defmodule ClaimControllerTest.Metadata.Read.V2 do
  use VirtualCryptoWeb.RestCase, async: true
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  use VirtualCryptoWeb.TestDataVerifier

  setup :setup_money

  setup %{conn: conn} = d do
    Map.put(
      d,
      :conn,
      VirtualCryptoWeb.Plug.DiscordApiService.set_service(
        conn,
        VirtualCryptoWeb.ClaimTest.TestDiscordAPI
      )
    )
  end

  test "get claimant metadata by id",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        %{
          "a" => "b",
          "e" => "f"
        }
      )

    conn =
      get(
        conn,
        Routes.v2_claim_path(conn, :get_by_id, id)
      )

    res = json_response(conn, 200)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{
        "a" => "b",
        "e" => "f"
      }
    })
  end

  test "get claims",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])
    amount1 = 40
    amount2 = 80

    {:ok, %{claim: %{id: _id1}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount1,
        %{
          "a" => "b",
          "e" => "f"
        }
      )

    {:ok, %{claim: %{id: id2}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user2},
        %DiscordUser{id: user1},
        unit,
        amount2,
        %{
          "a" => "b",
          "e" => "f"
        }
      )

    VirtualCrypto.Money.update_metadata(
      id2,
      %DiscordUser{id: user1},
      %{
        "a" => "c",
        "h" => "d"
      }
    )

    conn =
      get(
        conn,
        Routes.v2_claim_path(conn, :me)
      )

    res = json_response(conn, 200)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res |> Enum.at(0), %{
      amount: amount2,
      claimant: user2,
      payer: user1,
      currency: currency,
      status: "pending",
      metadata: %{
        "a" => "c",
        "h" => "d"
      }
    })

    verify_claim(res |> Enum.at(1), %{
      amount: amount1,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{
        "a" => "b",
        "e" => "f"
      }
    })
  end
end
