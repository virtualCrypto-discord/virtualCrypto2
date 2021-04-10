defmodule VirtualCryptoWeb.Api.InteractionsController do
  use VirtualCryptoWeb, :controller

  defp get_signature([]) do
    nil
  end

  defp get_signature([{"x-signature-ed25519", value} | _tail]) do
    value
  end

  defp get_signature([_ | tail]) do
    get_signature(tail)
  end

  defp get_timestamp([]) do
    nil
  end

  defp get_timestamp([{"x-signature-timestamp", value} | _tail]) do
    value
  end

  defp get_timestamp([_ | tail]) do
    get_timestamp(tail)
  end

  defp parse_options(options) do
    options
    |> Enum.map(fn option ->
      case option do
        %{"name" => name, "options" => options_} ->
          [{"subcommand", name}, {"sub_options", parse_options(options_)}]

        %{"name" => name, "value" => value} ->
          {name, value}

        %{"name" => name} ->
          {"subcommand", name}
      end
    end)
    |> List.flatten()
    |> Map.new()
  end

  def verify(conn) do
    public_key = Application.get_env(:virtualCrypto, :public_key) |> Base.decode16!(case: :lower)
    encoded_signature = conn.req_headers |> get_signature

    timestamp = get_timestamp(conn.req_headers)

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

  def verified(conn, %{"type" => 1}) do
    render(conn, "pong.json")
  end

  def verified(conn, %{"type" => 2, "data" => %{"name" => name} = data} = params) do
    options =
      Map.get(data, "options", [])
      |> parse_options

    render(conn, name <> ".json",
      params: VirtualCryptoWeb.CommandHandler.handle(name, options, params, conn)
    )
  end

  def verified(conn, _) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, "Type Not Found")
  end

  def index(conn, params) do
    if verify(conn),
      do: verified(conn, params),
      else:
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(401, "invalid request signature")
  end
end
