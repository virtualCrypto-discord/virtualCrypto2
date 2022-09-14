defmodule VirtualCrypto.EnvironmentBootstrapper do
  alias VirtualCrypto.Repo
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  def counter() do
    System.unique_integer([:positive])
  end

  @spec setup_money(map) :: %{
          :currency => non_neg_integer,
          :currency2 => non_neg_integer,
          :currency2_guild => non_neg_integer,
          :currency_guild => non_neg_integer,
          :guild => non_neg_integer,
          :guild2 => non_neg_integer,
          :name => String.t(),
          :name2 => String.t(),
          :unit => String.t(),
          :unit2 => String.t(),
          :user1 => non_neg_integer,
          :user2 => non_neg_integer,
          optional(any) => any
        }
  def setup_money(ctx) do
    guild = counter()
    guild2 = counter()

    user1 = counter()
    user2 = counter()
    unit = "n#{guild}"
    unit2 = "w#{guild}"
    name = "nyan#{guild}"
    name2 = "wan#{guild}"

    {:ok,_} =
      VirtualCryptoLegacyIssuer.enact_monetary_system(%{
        guild: guild,
        name: name,
        unit: unit,
        creator: %DiscordUser{id: user1},
        creator_amount: 1000 * 200
      })

    {:ok,_} =
      VirtualCryptoLegacyIssuer.enact_monetary_system(%{
        guild: guild2,
        name: name2,
        unit: unit2,
        creator: %DiscordUser{id: user2},
        creator_amount: 1000 * 200
      })

    currency = Repo.get_by(VirtualCrypto.Money.Currency, unit: unit)
    currency2 = Repo.get_by(VirtualCrypto.Money.Currency, unit: unit2)

    {:ok} =
      VirtualCrypto.Money.pay(
        sender: %DiscordUser{id: user1},
        receiver: %DiscordUser{id: user2},
        amount: 500,
        unit: "n#{guild}"
      )

    {:ok, _} =
      VirtualCryptoLegacyIssuer.issue(%{receiver: %DiscordUser{id: user2}, amount: 500, guild: guild})

    Map.merge(ctx, %{
      user1: user1,
      guild: guild,
      guild2: guild2,
      user2: user2,
      unit: unit,
      unit2: unit2,
      name: name,
      name2: name2,
      currency: currency.id,
      currency_guild: guild,
      currency2: currency2.id,
      currency2_guild: guild2
    })
  end

  @spec create_claim(non_neg_integer(), non_neg_integer(), String.t(), non_neg_integer()) ::
          {:ok, VirtualCrypto.Money.claim_t()}
  defp create_claim(user_id1, user_id2, unit, amount) do
    VirtualCrypto.Money.create_claim(
      %DiscordUser{id: user_id1},
      %DiscordUser{id: user_id2},
      unit,
      amount,
      nil
    )
  end

  @spec setup_claim(map()) :: %{
          :currency => non_neg_integer,
          :currency2 => non_neg_integer,
          :currency2_guild => non_neg_integer,
          :currency_guild => non_neg_integer,
          :guild => non_neg_integer,
          :guild2 => non_neg_integer,
          :name => String.t(),
          :name2 => String.t(),
          :unit => String.t(),
          :unit2 => String.t(),
          :user1 => non_neg_integer,
          :user2 => non_neg_integer,
          :claims => list(VirtualCrypto.Money.claim_t()),
          optional(any) => any
        }
  def setup_claim(ctx) do
    d = setup_money(ctx)

    {:ok, c1} =
      create_claim(
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c2} =
      create_claim(
        d.user2,
        d.user1,
        d.unit,
        9_999_999
      )

    {:ok, %{claim: c}} =
      create_claim(
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c3} = VirtualCrypto.Money.approve_claim(c.id, %DiscordUser{id: d.user2}, %{})

    {:ok, %{claim: c}} =
      create_claim(
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c4} = VirtualCrypto.Money.deny_claim(c.id, %DiscordUser{id: d.user2}, %{})

    {:ok, %{claim: c}} =
      create_claim(
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c5} = VirtualCrypto.Money.cancel_claim(c.id, %DiscordUser{id: d.user1}, %{})

    {:ok, c6} =
      create_claim(
        d.user1,
        d.user1,
        d.unit,
        100
      )

    Map.put(d, :claims, [c1, c2, c3, c4, c5, c6])
  end

  def approved_claim(claims), do: claims |> Enum.at(2)
  def denied_claim(claims), do: claims |> Enum.at(3)
  def canceled_claim(claims), do: claims |> Enum.at(4)

  def set_user_auth(conn, kind, uid, scopes) do
    {:ok, conn} =
      case {kind, uid, scopes} do
        {:app, uid, scopes} ->
          {:ok, token, _claims} = VirtualCrypto.Guardian.issue_token_for_app(uid, scopes)

          conn =
            conn
            |> Plug.Conn.put_req_header(
              "authorization",
              "Bearer #{token}"
            )

          {:ok, conn}

        {:user, uid, scopes} ->
          {:ok, user} = VirtualCrypto.User.insert_user_if_not_exists(uid)
          {:ok, token, _claims} = VirtualCrypto.Guardian.issue_token_for_user(user.id, scopes)

          conn =
            conn
            |> Plug.Conn.put_req_header(
              "authorization",
              "Bearer #{token}"
            )

          {:ok, conn}
      end

    conn
  end

  @spec sign_request(Plug.Conn.t(), binary()) :: Plug.Conn.t()
  def sign_request(conn, body) do
    public_key = Application.get_env(:virtualCrypto, :public_key) |> Base.decode16!(case: :lower)
    private_key = Application.get_env(:virtualCrypto, :private_key)

    timestamp = to_string(System.system_time(:second))

    conn
    |> Plug.Conn.put_req_header("x-signature-timestamp", timestamp)
    |> Plug.Conn.put_req_header(
      "x-signature-ed25519",
      :public_key.sign(timestamp <> body, :none, {:ed_pri, :ed25519, public_key, private_key})
      |> Base.encode16(case: :lower)
    )
  end
end
