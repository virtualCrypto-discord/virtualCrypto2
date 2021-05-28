defmodule VirtualCryptoWeb.Api.V1.ClaimController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money
  alias VirtualCryptoWeb.Filtering.Discord, as: Filtering
  import VirtualCryptoWeb.Plug.DiscordApiService, only: [get_service: 1]

  defp get_discord_user(discord_user_id, service) do
    user = Discord.Api.Cached.get_user(discord_user_id, service)

    Filtering.user(user)
  end

  defp format_claim(%{claim: claim,currency: currency, claimant: claimant, payer: payer}, service) do
    %{
      "id" => claim.id |> to_string,
      "currency" => %{
        "name" => currency.name,
        "unit" => currency.unit,
        "guild" => to_string(currency.guild_id),
        "pool_amount" => to_string(currency.pool_amount)
      },
      "amount" => to_string(claim.amount),
      "claimant" => %{
        "id" => to_string(claimant.id),
        "discord" =>
          if(claimant.discord_id != nil,
            do: get_discord_user(claimant.discord_id, service),
            else: nil
          )
      },
      "payer" => %{
        "id" => to_string(payer.id),
        "discord" =>
          if(payer.discord_id != nil, do: get_discord_user(payer.discord_id, service), else: nil)
      },
      "created_at" => claim.inserted_at,
      "updated_at" => claim.updated_at,
      "status" => claim.status
    }
  end

  defp format_claims(claims, service) do
    claims
    |> Enum.map(fn claim -> format_claim(claim, service) end)
  end

  defp permission_denied(conn) do
    conn
    |> put_status(403)
    |> render("error.json", error: :insufficient_scope, error_description: :permission_denied)
  end

  def me(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => user_id, "vc.claim" => true} ->
        claims = Money.get_claims(Money.VCService, user_id, ["pending"])

        render(conn, "data.json", params: format_claims(claims, get_service(conn)))

      _ ->
        conn |> permission_denied()
    end
  end

  def post(conn, %{"payer_discord_id" => payer_discord_id, "unit" => unit, "amount" => amount})
      when is_binary(payer_discord_id) and is_binary(amount) do
    case {Guardian.Plug.current_resource(conn), Integer.parse(payer_discord_id),
          Integer.parse(amount)} do
      {%{"sub" => user_id, "vc.claim" => true}, {payer_discord_id, ""}, {amount, ""}} ->
        case Money.create_claim(Money.VCService, user_id, payer_discord_id, unit, amount) do
          {:ok, claim} ->
            conn
            |> put_status(201)
            |> render("data.json", params: format_claim(claim, get_service(conn)))

          {:error, :invalid_amount} ->
            conn
            |> put_status(400)
            |> render("error.json", error: :invalid_request, error_description: :invalid_amount)

          {:error, :money_not_found} ->
            conn
            |> put_status(400)
            |> render("error.json", error: :invalid_request, error_description: :money_not_found)
        end

      {_, :error, _} ->
        conn
        |> put_status(400)
        |> render("error.json",
          error: :invalid_request,
          error_description: :invalid_payer_discord_id_value
        )

      {_, {_, x}, _} when x != "" ->
        conn
        |> put_status(400)
        |> render("error.json",
          error: :invalid_request,
          error_description: :invalid_payer_discord_id_value
        )

      {_, _, :error} ->
        conn
        |> put_status(400)
        |> render("error.json", error: :invalid_request, error_description: :invalid_amount_value)

      {_, _, {_, x}} when x != "" ->
        conn
        |> put_status(400)
        |> render("error.json", error: :invalid_request, error_description: :invalid_amount_value)

      {%{"sub" => _, "vc.claim" => false}, _, _} ->
        conn |> permission_denied()
    end
  end

  def post(conn, %{"payer_discord_id" => payer_discord_id})
      when not is_binary(payer_discord_id) do
    conn
    |> put_status(400)
    |> render("error.json",
      error: :invalid_request,
      error_description: :invalid_payer_discord_id_type
    )
  end

  def post(conn, %{"amount" => amount}) when not is_binary(amount) do
    conn
    |> put_status(400)
    |> render("error.json", error: :invalid_request, error_description: :invalid_amount_type)
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
            render(conn, "data.json", params: format_claim(claim, get_service(conn)))

          {:error, status} when status in [:not_found, :invalid_operator, :invalid_status] ->
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

      {%{"sub" => _, "vc.claim" => false}, _} ->
        conn |> permission_denied()

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

  def patch(conn, %{"id" => _id}) do
    conn
    |> put_status(400)
    |> render("error.json", error: :invalid_request, error_description: :must_supply_valid_status)
  end

  def get_by_id(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => user_id, "vc.claim" => true} ->
        case Money.get_claim_by_id(id) do
          %{payer: %VirtualCrypto.User.User{id: ^user_id}} = d ->
            render(conn, "data.json", params: format_claim(d, get_service(conn)))

          %{claimant: %VirtualCrypto.User.User{id: ^user_id}} = d ->
            render(conn, "data.json", params: format_claim(d, get_service(conn)))

          _ ->
            conn
            |> put_status(404)
            |> render("error.json", error: :not_found, error_description: :not_found)
        end

      _ ->
        conn |> permission_denied()
    end
  end
end
