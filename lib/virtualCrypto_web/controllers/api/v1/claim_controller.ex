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
    case Guardian.Plug.current_resource(conn) do
      {:ok, %{"sub" => user_id}} ->
        {sent, received} = Money.get_pending_claims(Money.VCService, user_id)
        render(conn, "claim.json", params: %{sent: sent |> format, received: received |> format})

      _ ->
        {:error, {:invalid_token, :invalid_token}}
    end
  end

  def post(conn, %{"payer_discord_id" => payer_discord_id, "unit" => unit, "amount" => amount}) do
    case Guardian.Plug.current_resource(conn) do

  def get_by_id(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => user_id, "vc.claim" => true} ->
        case Money.get_claim_by_id(id) do
          {_, _, %VirtualCrypto.User.User{id: ^user_id}, _} = d ->
            render(conn, "data.json", params: d |> format_claim)

          {_, _, _, %VirtualCrypto.User.User{id: ^user_id}} = d ->
            render(conn, "data.json", params: d |> format_claim)

          _ ->
            conn
            |> put_status(404)
            |> render("error.json", error: :not_found, error_description: :not_found)
        end
    end
  end
end
