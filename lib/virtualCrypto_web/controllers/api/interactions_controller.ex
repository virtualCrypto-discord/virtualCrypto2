defmodule VirtualCryptoWeb.Api.InteractionsController do
  use VirtualCryptoWeb, :controller
  alias VirtualCryptoWeb.Interaction.CustomId

  defp parse_options(options) do
    options
    |> Enum.map(fn
      %{"name" => name, "options" => options} ->
        [{"subcommand", name}, {"sub_options", parse_options(options)}]

      # FIXME: #294
      %{"name" => name, "value" => value} when is_binary(value) ->
        {name, value |> String.trim()}

      %{"name" => name, "value" => value} ->
        {name, value}

      %{"name" => name} ->
        {"subcommand", name}
    end)
    |> List.flatten()
    |> Map.new()
  end

  def verify(conn) do
    public_key = Application.get_env(:virtualCrypto, :public_key) |> Base.decode16!(case: :lower)

    encoded_signature =
      case Plug.Conn.get_req_header(conn, "x-signature-ed25519") do
        [encoded_signature] -> encoded_signature
        _ -> nil
      end

    timestamp =
      case Plug.Conn.get_req_header(conn, "x-signature-timestamp") do
        [timestamp] -> timestamp
        _ -> nil
      end

    case {encoded_signature, timestamp} do
      {nil, _} ->
        false

      {_, nil} ->
        false

      _ ->
        case encoded_signature |> Base.decode16(case: :lower) do
          {:ok, signature} ->
            body = hd(conn.assigns.raw_body)
            message = timestamp <> body

            :public_key.verify(
              message,
              :none,
              signature,
              {:ed_pub, :ed25519, public_key}
            )

          :error ->
            false
        end
    end
  end

  defp handle_button(conn, [:claim, :action, :back] = path, data, params) do
    {name, params} =
      VirtualCryptoWeb.Interaction.Button.handle(
        path,
        data,
        params,
        conn
      )

    render(conn, "#{name}.json", params: params)
  end

  defp handle_button(
         conn,
         [:claim, :action, _] = path,
         data,
         %{"token" => token, "application_id" => application_id} = params
       ) do
    {{name, params}, webhook_body} =
      VirtualCryptoWeb.Interaction.Button.handle(
        path,
        data,
        params,
        conn
      )

    conn = render(conn, "#{name}.json", params: params)
    adapter = VirtualCryptoWeb.Plug.DiscordApiService.get_service(conn)

    {200, _} =
      adapter.post_webhook_message(
        application_id,
        token,
        webhook_body
      )

    conn
  end

  defp handle_button(conn, path, data, params) do
    {name, params} =
      VirtualCryptoWeb.Interaction.Button.handle(
        path,
        data,
        params,
        conn
      )

    render(conn, "#{name}.json", params: params)
  end

  def verified(conn, %{"type" => 1}) do
    render(conn, "pong.json")
  end

  def verified(conn, %{"type" => 2, "data" => %{"name" => name} = data} = params) do
    options =
      Map.get(data, "options", [])
      |> parse_options

    render(conn, name <> ".json",
      params: VirtualCryptoWeb.Interaction.Command.handle(name, options, params, conn)
    )
  end

  def verified(
        conn,
        %{"type" => 3, "data" => %{"custom_id" => custom_id, "component_type" => 2}} = params
      ) do
    {path, data} = custom_id |> CustomId.parse() |> CustomId.UI.Button.parse()

    handle_button(conn, path, data, params)
  end

  def verified(
        conn,
        %{
          "type" => 3,
          "data" => %{"custom_id" => custom_id, "component_type" => 3} = d
        } = params
      ) do
    {path, data} =
      custom_id
      |> CustomId.parse()
      |> CustomId.UI.SelectMenu.parse()

    Map.get(d, "values", [])

    {name, params} =
      VirtualCryptoWeb.Interaction.SelectMenu.handle(
        path,
        data,
        Map.get(d, "values", []),
        params,
        conn
      )

    render(conn, "#{name}.json", params: params)
  end

  def verified(conn, _) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, "Type Not Found")
    |> halt()
  end

  def index(conn, params) do
    if verify(conn),
      do: verified(conn, params),
      else:
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(401, "invalid request signature")
        |> halt()
  end
end
