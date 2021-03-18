defmodule VirtualCryptoWeb.EnviromentBootstrapper do
  alias VirtualCrypto.Repo

  def counter() do
    System.unique_integer([:positive])
  end

  def setup_money(ctx) do
    guild = counter()
    guild2 = counter()

    user1 = counter()
    user2 = counter()
    unit = "n#{guild}"
    unit2 = "w#{guild}"
    name = "nyan#{guild}"
    name2 = "wan#{guild}"

    {:ok} =
      VirtualCrypto.Money.create(
        guild: guild,
        name: name,
        unit: unit,
        creator: user1,
        creator_amount: 1000 * 200
      )

    {:ok} =
      VirtualCrypto.Money.create(
        guild: guild2,
        name: name2,
        unit: unit2,
        creator: user2,
        creator_amount: 1000 * 200
      )

    currency = Repo.get_by(VirtualCrypto.Money.Info, unit: unit)
    currency2 = Repo.get_by(VirtualCrypto.Money.Info, unit: unit2)

    {:ok} =
      VirtualCrypto.Money.pay(VirtualCrypto.Money.DiscordService,
        sender: user1,
        receiver: user2,
        amount: 500,
        unit: "n#{guild}"
      )

    {:ok, _} = VirtualCrypto.Money.give(receiver: user2, amount: 500, guild: guild)

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
      currency2: currency2.id
    })
  end

  def setup_claim(ctx) do
    d = setup_money(ctx)

    {:ok, c1} =
      VirtualCrypto.Money.create_claim(
        VirtualCrypto.Money.DiscordService,
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c2} =
      VirtualCrypto.Money.create_claim(
        VirtualCrypto.Money.DiscordService,
        d.user2,
        d.user1,
        d.unit,
        9_999_999
      )

    {:ok, {c, _, _, _}} =
      VirtualCrypto.Money.create_claim(
        VirtualCrypto.Money.DiscordService,
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c3} =
      VirtualCrypto.Money.approve_claim(VirtualCrypto.Money.DiscordService, c.id, d.user2)

    {:ok, {c, _, _, _}} =
      VirtualCrypto.Money.create_claim(
        VirtualCrypto.Money.DiscordService,
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c4} = VirtualCrypto.Money.deny_claim(VirtualCrypto.Money.DiscordService, c.id, d.user2)

    {:ok, {c, _, _, _}} =
      VirtualCrypto.Money.create_claim(
        VirtualCrypto.Money.DiscordService,
        d.user1,
        d.user2,
        d.unit,
        500
      )

    {:ok, c5} =
      VirtualCrypto.Money.cancel_claim(VirtualCrypto.Money.DiscordService, c.id, d.user1)

    {:ok, c6} =
      VirtualCrypto.Money.create_claim(
        VirtualCrypto.Money.DiscordService,
        d.user1,
        d.user1,
        d.unit,
        100
      )

    Map.put(d, :claims, [c1, c2, c3, c4, c5, c6])
  end

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
end
