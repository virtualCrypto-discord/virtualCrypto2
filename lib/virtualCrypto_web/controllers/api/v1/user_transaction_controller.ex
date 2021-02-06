defmodule VirtualCryptoWeb.Api.V1.UserTransactionController do
  use VirtualCryptoWeb, :controller

  def post(conn, %{
        "unit" => unit,
        "receiver_discord_id" => receiver_discord_id,
        "amount" => amount
      }) do
    params =
      with {:validate_token, %{"sub" => user_id, "vc.pay" => true}} <-
             {:validate_token, Guardian.Plug.current_resource(conn)},
           {:receiver_discord_id, {int_receiver_discord_id, ""}} <-
             {:receiver_discord_id, receiver_discord_id |> Integer.parse()},
           {:amount, int_amount} when int_amount != :error <-
             {:amount, amount |> JsonUtil.parse_to_integer()} do
        VirtualCrypto.Money.pay(VirtualCrypto.Money.VCService,
          sender: user_id,
          receiver: int_receiver_discord_id,
          unit: unit,
          amount: int_amount
        )
      else
        {:validate_token, _} ->
          {:error, {:invalid_token, :token_verfication_failed}}

        {:receiver_discord_id, _} ->
          {:error, {:invalid_request, :receiver_discord_id_must_be_digit_string}}

        {:amount, _} ->
          {:error,
           {:invalid_request,
            :amount_be_digit_string_or_can_integer_if_under_safe_integer_max_value}}
      end

    case params do
      {:ok} -> conn |> send_resp(204, "")
      {:error, err} -> conn |> put_status(400) |> render("error.json", error: err)
    end
  end

  def post(conn, _) do
    conn
    |> put_status(400)
    |> render("error.json", error: {:invalid_request, :missing_parameter})
  end
end
