defmodule VirtualCryptoWeb.Api.V1.ClaimController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money
  alias VirtualCryptoWeb.Filtering.Disocrd, as: Filtering

  defp get_discord_user(discord_user_id) do
    user = Discord.Api.V8.get_user(discord_user_id)

    Filtering.user(user)
  end

  defp format_claim({claim, info, claimant, payer}) do
    %{
      "id" => claim.id |> to_string,
      "currency" => %{
        "name" => info.name,
        "unit" => info.unit,
        "guild" => to_string(info.guild_id),
        "pool_amount" => to_string(info.pool_amount)
      },
      "amount" => to_string(claim.amount),
      "claimant" => %{
        "id" => to_string(claimant.id),
        "discord" =>
          if(claimant.discord_id != nil, do: get_discord_user(claimant.discord_id), else: nil)
      },
      "payer" => %{
        "id" => to_string(payer.id),
        "discord" =>
          if(payer.discord_id != nil, do: get_discord_user(payer.discord_id), else: nil)
      },
      "created_at" => claim.inserted_at,
      "updated_at" => claim.updated_at,
      "status" => claim.status
    }
  end

  defp format_claims(claims) do
    claims
    |> Enum.map(&format_claim/1)
  end

  defp permission_denied(conn) do
    conn
    |> put_status(403)
    |> render("error.json", error: :invalid_token, error_description: :permission_denied)
  end

  def me(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => user_id, "vc.claim" => true} ->
        claims = Money.get_claims(Money.VCService, user_id, "pending")

        render(conn, "data.json", params: claims |> format_claims)

      _ ->
        conn |> permission_denied()
    end
  end

  def post(conn, %{"payer_discord_id" => payer_discord_id, "unit" => unit, "amount" => amount}) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => user_id, "vc.claim" => true} ->
        case Money.create_claim(Money.VCService, user_id, payer_discord_id, unit, amount) do
          {:ok, claim} ->
            conn
            |> put_status(201)

            render(conn, "data.json", params: claim |> format_claim)

          {:error, :invalid_amount} ->
            conn
            |> put_status(400)
            |> render("error.json", error: :invalid_request, error_description: :invalid_amount)

          {:error, :money_not_found} ->
            conn
            |> put_status(400)
            |> render("error.json", error: :invalid_request, error_description: :money_not_found)
        end

      _ ->
        conn |> permission_denied()
    end
  end

  def post(conn, %{"payer_discord_id" => _payer_discord_id, "unit" => _unit}) do
    conn
    |> put_status(400)
    |> render("error.json", error: :invalid_request, error_description: :amount_field_is_required)
  end

  def post(conn, %{"payer_discord_id" => _payer_discord_id}) do
    conn
    |> put_status(400)
    |> render("error.json", error: :invalid_request, error_description: :unit_field_is_required)
  end

  def post(conn, %{}) do
    conn
    |> put_status(400)
    |> render("error.json",
      error: :invalid_request,
      error_description: :payer_discord_id_field_is_required
    )
  end

  defp patch_(conn, id, f) do
    case {Guardian.Plug.current_resource(conn), Integer.parse(id)} do
      {%{"sub" => user_id, "vc.claim" => true}, {int_id, ""}} ->
        case f.(Money.VCService, int_id, user_id) do
          {:ok, claim} ->
            render(conn, "data.json", params: claim |> format_claim)

          {:error, :not_found} ->
            conn
            |> put_status(404)
            |> render("error.json", error: :not_found, error_description: :not_found)

          {:error, :not_found_money} ->
            conn
            |> put_status(400)
            |> render("error.json", error: :invalid_request, error_description: :not_found_money)

          {:error, :not_found_sender_asset} ->
            conn
            |> put_status(400)
            |> render("error.json",
              error: :not_enough_amount,
              error_description: :not_enough_amount
            )

          {:error, :not_enough_amount} ->
            conn
            |> put_status(400)
            |> render("error.json",
              error: :not_enough_amount,
              error_description: :not_enough_amount
            )
        end

      {_, :error} ->
        conn
        |> put_status(404)
        |> render("error.json", error: :not_found, error_description: :not_found)

      {_, {_x, _}} ->
        conn
        |> put_status(404)
        |> render("error.json", error: :not_found, error_description: :not_found)

      _ ->
        conn |> permission_denied()
    end
  end

  def patch(conn, %{"id" => id, "status" => "approved"}) do
    patch_(conn, id, &Money.approve_claim/3)
  end

  def patch(conn, %{"id" => id, "status" => "denied"}) do
    patch_(conn, id, &Money.deny_claim/3)
  end

  def patch(conn, %{"id" => id, "status" => "canceled"}) do
    patch_(conn, id, &Money.cancel_claim/3)
  end

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
