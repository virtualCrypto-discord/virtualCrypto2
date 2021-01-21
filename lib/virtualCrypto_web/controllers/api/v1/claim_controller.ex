defmodule VirtualCryptoWeb.Api.V1.ClaimController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money

  def get_name(discord_user_id) do
    data = Discord.Api.V8.get_user(discord_user_id)
    ~s/@#{data["username"]}##{data["discriminator"]}/
  end

  def format(data) do
    data
    |> Enum.map(fn {claim, info, claimant, _payer} ->
      %{
        "id" => claim.id |> to_string,
        "unit" => info.unit,
        "amount" => claim.amount,
        "claimant" => %{"name" => get_name(claimant.discord_id)},
        "payer" => %{"name" => get_name(claimant.discord_id)},
        "created_at" => claim.inserted_at
      }
    end)
  end

  def me(conn, _) do
    case Guardian.Plug.current_token(conn) do
      nil ->
        {:error}

      token ->
        {:ok, %{"sub" => user_id}} = VirtualCrypto.Guardian.decode_and_verify(token)
        {sent, received} = Money.get_pending_claims(Money.VCService, user_id)
        render(conn, "claim.json", params: %{sent: sent |> format, received: received |> format})
    end
  end
end
