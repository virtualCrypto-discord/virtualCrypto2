defmodule VirtualCryptoWeb.Api.V1.UserTransactionController do
  use VirtualCryptoWeb, :controller

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
        VirtualCrypto.Money.pay(VirtualCrypto.Money.VCService,
          sender: user_id,
          receiver: int_receiver_discord_id,
          unit: unit,
          amount: int_amount
        )
      else
        {:convert_receiver_discord_id, _} ->
          {:error, {:invalid_request, :invalid_format_of_receiver_discord_id}}

        {:convert_amount, _} ->
          {:error, {:invalid_request, :invalid_format_of_convert_amount}}

        _ ->
          {:error, {:invalid_token, :token_verfication_failed}}
      end

    case params do
      {:ok} -> conn |> send_resp(204, "")
      {:error, err} -> conn |> put_status(400) |> render("error.json", error: err)
    end
  end

  def post(conn, %{
        "unit" => _unit,
        "receiver_discord_id" => _receiver_discord_id,
        "amount" => _amount
      }) do
    conn
    |> put_status(400)
    |> render("error.json", error: {:invalid_request, :invalid_type_of_variable})
  end

  def post(conn, _) do
    conn
    |> put_status(400)
    |> render("error.json", error: {:invalid_request, :missing_parameter})
  end
end
