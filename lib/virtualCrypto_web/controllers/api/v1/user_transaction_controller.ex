defmodule VirtualCryptoWeb.Api.V1.UserTransactionController do
  use VirtualCryptoWeb, :controller

  def post(conn, %{
        "unit" => unit,
        "receiver_discord_id" => receiver_discord_id,
        "amount" => amount
      }) do
    params =
      with %{"sub" => user_id, "vc.pay" => true} <- Guardian.Plug.current_resource(conn) do
        VirtualCrypto.Money.pay(VirtualCrypto.Money.VCService,
          sender: user_id,
          receiver: receiver_discord_id,
          unit: unit,
          amount: amount
        )
      else
        _ -> {:error, {:invalid_token, :token_verfication_failed}}
      end

    case params do
      {:ok} -> conn |> send_resp(204, "")
      {:error, err} -> render("error.json", error: err)
    end
  end

  def post(conn, _) do
    conn
    |> put_status(400)
    |> render("error.json", error: {:invalid_request, :missing_parameter})
  end
end
