defmodule VirtualCryptoWeb.Api.V2.UserTransactionController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCrypto.Exterior.User.VirtualCrypto, as: VCUser

  plug(VirtualCryptoWeb.IdempotencyLayer.Plug,
    behavior: VirtualCryptoWeb.IdempotencyLayer.Payments
  )

  plug(:reject_duplicate_request)

  def reject_duplicate_request(conn, _) do
    idempotency = Map.get(conn.assigns, :idempotency, %{state: :nothing})
    entry = Map.get(idempotency, :entry, %{http_status: nil})

    case {idempotency.state, entry.http_status} do
      {:exist, nil} ->
        conn
        |> put_status(409)
        |> put_resp_header("idempotency-status", "Duplicate")
        |> render("pass.json",
          _json: %{error: "processing", error_description: "should_retry_after_in_seconds"}
        )
        |> Plug.Conn.halt()

      {:exist, http_status} ->
        conn
        |> put_status(http_status)
        |> put_resp_header("idempotency-status", "Duplicate")
        |> render("pass.json", _json: entry.body)
        |> Plug.Conn.halt()

      {:create, nil} ->
        conn

      {:nothing, nil} ->
        conn
    end
  end

  defp _render(conn, template, params \\ []) do
    json =
      VirtualCryptoWeb.Api.V2.UserTransactionView.Pure.render(template, params |> Enum.into(%{}))

    conn =
      if Map.has_key?(conn.assigns, :idempotency) do
        VirtualCryptoWeb.IdempotencyLayer.Payments.register_response(conn, json)
        conn |> put_resp_header("idempotency-status", "OK")
      else
        conn |> put_resp_header("idempotency-status", "Not Requested")
      end

    render(conn, "pass.json", %{_json: json})
  end

  def post(conn, %{
        "unit" => unit,
        "receiver_discord_id" => receiver_discord_id,
        "amount" => amount
      })
      when is_binary(unit) and is_binary(amount) and is_binary(receiver_discord_id) do
    params =
      with {:convert_receiver_discord_id, {int_receiver_discord_id, ""}} <-
             {:convert_receiver_discord_id, Integer.parse(receiver_discord_id)},
           {:convert_amount, {int_amount, ""}} <-
             {:convert_amount, Integer.parse(amount)},
           %{"sub" => user_id, "vc.pay" => true} <- Guardian.Plug.current_resource(conn) do
        VirtualCrypto.Money.pay(
          sender: %VCUser{id: user_id},
          receiver: %DiscordUser{id: int_receiver_discord_id},
          unit: unit,
          amount: int_amount
        )
      else
        {:convert_receiver_discord_id, _} ->
          {:error, {:invalid_request, :invalid_format_of_receiver_discord_id}}

        {:convert_amount, _} ->
          {:error, {:invalid_request, :invalid_format_of_convert_amount}}

        _ ->
          {:error, {:insufficient_scope, :token_verification_failed}}
      end

    case params do
      {:ok} ->
        conn |> put_status(201) |> _render("ok.json")

      {:error, {:insufficient_scope, _} = err} ->
        conn |> put_status(403) |> _render("error.json", error: err)

      {:error, err} when err in [:not_enough_amount, :not_found_sender_asset] ->
        conn |> put_status(409) |> _render("error.json", error: err)

      {:error, err} ->
        conn |> put_status(400) |> _render("error.json", error: err)
    end
  end

  def post(conn, %{
        "unit" => _unit,
        "receiver_discord_id" => _receiver_discord_id,
        "amount" => _amount
      }) do
    conn
    |> put_status(400)
    |> _render("error.json", error: {:invalid_request, :invalid_type_of_variable})
  end

  def post(conn, %{"_json" => list}) when is_list(list) do
    with {:param, param} when is_list(param) <- {:param, convert_list(list)},
         {:token, %{"sub" => user_id, "vc.pay" => true}} <-
           {:token, Guardian.Plug.current_resource(conn)},
         {:ok, _} <- VirtualCrypto.Money.create_payments(%VCUser{id: user_id}, param) do
      conn |> put_status(201) |> _render("ok.json")
    else
      {:param, {tag, idx}} ->
        conn
        |> put_status(400)
        |> _render("error.json", error: {:invalid_request, "invalid_#{tag}_at_#{idx}"})

      {:token, _} ->
        conn
        |> put_status(403)
        |> _render("error.json", error: {:insufficient_scope, :token_verification_failed})

      {:error, :not_enough_amount} ->
        conn |> put_status(409) |> _render("error.json", error: :not_enough_amount)

      {:error, err} ->
        conn |> put_status(400) |> _render("error.json", error: err)
    end
  end

  def post(conn, _) do
    conn
    |> put_status(400)
    |> _render("error.json", error: {:invalid_request, :missing_parameter})
  end

  defp convert_list(list) do
    list
    |> Enum.with_index()
    |> Enum.reduce_while([], fn {elem, idx}, acc ->
      with %{} <- elem,
           {:amount, {:ok, amount}} when is_binary(amount) <-
             {:amount, Map.fetch(elem, "amount")},
           {:amount, {int_amount, ""}} <- {:amount, Integer.parse(amount)},
           {:unit, {:ok, unit}} <- {:unit, Map.fetch(elem, "unit")},
           {:receiver_discord_id, {:ok, receiver_discord_id}} when is_binary(amount) <-
             {:receiver_discord_id, Map.fetch(elem, "receiver_discord_id")},
           {:receiver_discord_id, {int_receiver_discord_id, ""}} <-
             {:receiver_discord_id, Integer.parse(receiver_discord_id)} do
        {:cont,
         [
           %{amount: int_amount, unit: unit, receiver: %DiscordUser{id: int_receiver_discord_id}}
           | acc
         ]}
      else
        {tag, _} -> {:halt, {tag, idx}}
      end
    end)
  end
end
