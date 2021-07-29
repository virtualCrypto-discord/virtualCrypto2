defmodule VirtualCryptoWeb.Api.V2.ClaimController do
  use VirtualCryptoWeb, :controller
  alias VirtualCrypto.Money
  alias VirtualCryptoWeb.Filtering.Discord, as: Filtering
  alias VirtualCrypto.Exterior.User.VirtualCrypto, as: VCUser
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  import VirtualCryptoWeb.Plug.DiscordApiService, only: [get_service: 1]

  defp parse_user_argument(%{"related_discord_user" => _discord_user, "related_vc_user" => _user}) do
    :error
  end

  defp parse_user_argument(%{"related_discord_user" => discord_user}) do
    case Integer.parse(discord_user) do
      {x, ""} -> {:ok, %DiscordUser{id: x}}
      _ -> :error
    end
  end

  defp parse_user_argument(%{"related_vc_user" => vc_user}) do
    case Integer.parse(vc_user) do
      {x, ""} -> {:ok, %VCUser{id: x}}
      _ -> :error
    end
  end

  defp parse_user_argument(%{}) do
    {:ok, nil}
  end

  defp type(%{"type" => "received"}) do
    {:ok, :received}
  end

  defp type(%{"type" => "claimed"}) do
    {:ok, :claimed}
  end

  defp type(%{"type" => "all"}) do
    {:ok, :all}
  end

  defp type(%{"type" => _}) do
    :error
  end

  defp type(%{}) do
    {:ok, :all}
  end

  defp limit(%{"limit" => limit}) do
    case Integer.parse(limit) do
      {x, ""} -> {:ok, x}
      _ -> :error
    end
  end

  defp limit(%{}) do
    {:ok, nil}
  end

  defp parse_cursor(%{"next" => value}) do
    {:ok, %{cursor: {:next, value}}}
  end

  defp parse_cursor(%{}) do
    {:ok, %{cursor: :first}}
  end

  defp parse_order(nil) do
    {:ok, :desc_claim_id}
  end

  defp parse_order("desc_claim_id") do
    {:ok, :desc_claim_id}
  end

  defp parse_order("asc_claim_id") do
    {:ok, :asc_claim_id}
  end

  defp get_discord_user(discord_user_id, service) do
    user = Discord.Api.Cached.get_user(discord_user_id, service)

    Filtering.user(user)
  end

  defp format_claim(
         %{claim: claim, currency: currency, claimant: claimant, payer: payer},
         service
       ) do
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
      "created_at" => DateTime.from_naive!(claim.inserted_at, "Etc/UTC"),
      "updated_at" => DateTime.from_naive!(claim.updated_at, "Etc/UTC"),
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
    |> render("error.json", error: :invalid_token, error_description: :permission_denied)
  end

  defp invalid_request(conn, desc) do
    conn
    |> put_status(400)
    |> render("error.json", error: :invalid_request, error_description: desc)
  end

  defp build_url_from_options(
         %{host: host, request_path: request_path, port: port, scheme: scheme},
         options
       ) do
    %{
      statuses: statuses,
      related_user: related_user,
      type: type,
      limit: limit,
      next: next
    } = options

    related_user =
      case related_user do
        %DiscordUser{id: x} -> [{"related_discord_user", x}]
        %VCUser{id: x} -> [{"related_vc_user", x}]
        nil -> []
      end

    limit =
      case limit do
        nil -> []
        limit -> [{"limit", limit}]
      end

    query =
      URI.encode_query(
        [{"type", to_string(type)}, {"next", next}] ++
          limit ++ related_user ++ (statuses |> Enum.map(&{"statuses[]", &1}))
      )

    %URI{
      authority: host,
      fragment: nil,
      host: host,
      path: request_path,
      port: port,
      query: query,
      scheme: scheme |> to_string(),
      userinfo: nil
    }
  end

  @spec generate_link_header(Plug.Conn.t(), [VirtualCrypto.Money.claim_t()], map()) ::
          nil | binary()
  defp generate_link_header(_conn, _, %{limit: nil}) do
    nil
  end

  defp generate_link_header(conn, claims, %{limit: limit} = options) do
    v = claims |> List.last()

    next =
      if limit == claims |> length() do
        build_url_from_options(conn, Map.put(options, :next, v.claim.id))
      else
        nil
      end

    case next do
      nil -> nil
      _ -> "<#{next}>; rel=\"next\""
    end
  end

  def me(conn, params) do
    statuses =
      case params do
        %{"statuses" => []} -> ["pending"]
        %{"statuses" => x} when is_list(x) -> x
        %{} -> ["pending"]
      end

    related_user = parse_user_argument(params)
    type = type(params)
    limit = limit(params)
    cursor = parse_cursor(params)
    order = parse_order(params["order"])

    with {:valid_statuses, true} <-
           {:valid_statuses,
            statuses |> Enum.all?(fn v -> v in ["pending", "approved", "denied", "canceled"] end)},
         {:related_user_id, {:ok, related_user}} <- {:related_user_id, related_user},
         {:type, {:ok, type}} <- {:type, type},
         {:limit, {:ok, limit}} <- {:limit, limit},
         {:cursor, {:ok, cursor}} <- {:cursor, cursor},
         {:order, {:ok, order}} <- {:order, order},
         {:verify_user, %{"sub" => user_id, "vc.claim" => true}} <-
           {:verify_user, Guardian.Plug.current_resource(conn)} do
      claims =
        Money.get_claims(
          %VCUser{id: user_id},
          statuses,
          type,
          related_user,
          order,
          cursor,
          limit
        )

      conn =
        case generate_link_header(
               conn,
               claims,
               %{
                 statuses: statuses,
                 related_user: related_user,
                 type: type,
                 limit: limit,
                 order: order,
                 cursor: cursor
               }
             ) do
          nil -> conn
          link_header -> conn |> Plug.Conn.put_resp_header("link", link_header)
        end

      conn |> render("data.json", params: format_claims(claims, get_service(conn)))
    else
      {:valid_statuses, _} -> conn |> invalid_request(:invalid_statuses)
      {:verify_user, _} -> conn |> permission_denied()
      {:related_user_id, _} -> conn |> invalid_request(:invalid_related_user)
      {:type, _} -> conn |> invalid_request(:invalid_type)
      {:limit, _} -> conn |> invalid_request(:invalid_limit)
      {:cursor, _} -> conn |> invalid_request(:invalid_cursor)
    end
  end

  def post(conn, %{"payer_discord_id" => payer_discord_id, "unit" => unit, "amount" => amount})
      when is_binary(payer_discord_id) and is_binary(amount) do
    case {Guardian.Plug.current_resource(conn), Integer.parse(payer_discord_id),
          Integer.parse(amount)} do
      {%{"sub" => user_id, "vc.claim" => true}, {payer_discord_id, ""}, {amount, ""}} ->
        case Money.create_claim(
               %VCUser{id: user_id},
               %DiscordUser{id: payer_discord_id},
               unit,
               amount
             ) do
          {:ok, claim} ->
            conn
            |> put_status(201)
            |> render("data.json", params: format_claim(claim, get_service(conn)))

          {:error, :invalid_amount} ->
            conn
            |> put_status(400)
            |> render("error.json", error: :invalid_request, error_description: :invalid_amount)

          {:error, :not_found_currency} ->
            conn
            |> put_status(400)
            |> render("error.json",
              error: :invalid_request,
              error_description: :not_found_currency
            )
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
        case f.(int_id, %VCUser{id: user_id}) do
          {:ok, claim} ->
            render(conn, "data.json", params: format_claim(claim, get_service(conn)))

          {:error, :not_found} ->
            conn
            |> put_status(404)
            |> render("error.json", error: :not_found, error_description: :not_found)

          {:error, :invalid_status} ->
            conn
            |> put_status(409)
            |> render("error.json", error: :conflict, error_info: :invalid_status)

          {:error, :invalid_operator} ->
            conn
            |> put_status(403)
            |> render("error.json", error: :forbidden, error_description: :invalid_operator)

          {:error, :not_found_currency} ->
            conn
            |> put_status(400)
            |> render("error.json",
              error: :invalid_request,
              error_description: :not_found_currency
            )

          {:error, :not_found_sender_asset} ->
            conn
            |> put_status(409)
            |> render("error.json",
              error: :conflict,
              error_info: :not_enough_amount
            )

          {:error, :not_enough_amount} ->
            conn
            |> put_status(409)
            |> render("error.json",
              error: :conflict,
              error_info: :not_enough_amount
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
    end
  end

  def patch(conn, %{"id" => id, "status" => "approved"}) do
    patch_(conn, id, &Money.approve_claim/2)
  end

  def patch(conn, %{"id" => id, "status" => "denied"}) do
    patch_(conn, id, &Money.deny_claim/2)
  end

  def patch(conn, %{"id" => id, "status" => "canceled"}) do
    patch_(conn, id, &Money.cancel_claim/2)
  end

  def patch(conn, %{"id" => _id}) do
    conn
    |> put_status(400)
    |> render("error.json", error: :invalid_request, error_description: :must_supply_valid_status)
  end

  def get_by_id(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      %{"sub" => user_id, "vc.claim" => true} ->
        case VirtualCrypto.Money.get_claim_by_id(id) do
          %{payer: %VirtualCrypto.User.User{id: ^user_id}} = d ->
            render(conn, "data.json", params: format_claim(d, get_service(conn)))

          %{claimant: %VirtualCrypto.User.User{id: ^user_id}} = d ->
            render(conn, "data.json", params: format_claim(d, get_service(conn)))

          %{} ->
            conn
            |> put_status(403)
            |> render("error.json", error: :forbidden, error_description: :not_related_user)

          {:error, :not_found} ->
            conn
            |> put_status(404)
            |> render("error.json", error: :not_found, error_description: :not_found)
        end

      _ ->
        conn |> permission_denied()
    end
  end
end
