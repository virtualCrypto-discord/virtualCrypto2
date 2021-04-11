defmodule ClaimControllerTest.V2 do
  use VirtualCryptoWeb.RestCase, async: true
  import Enum, only: [at: 2]
  import String, only: [to_integer: 1]

  defmodule TestDiscordAPI do
    # @behaviour Discord.Api.Behavior

    def get_user(user_id) do
      %{"id" => to_string(user_id)}
    end
  end

  setup :setup_claim

  setup %{conn: conn} = d do
    Map.put(d, :conn, VirtualCryptoWeb.Plug.DiscordApiService.set_service(conn, TestDiscordAPI))
  end

  defp verify_claim(claim, %{
         amount: amount,
         claimant: claimant,
         payer: payer,
         currency: currency,
         status: status
       }) do
    assert to_integer(claim["amount"]) == amount
    assert claim["status"] == status
    verify_user(claim["claimant"], claimant)
    verify_user(claim["payer"], payer)
    verify_currency(claim["currency"], currency)
  end

  defp verify_user(user, user_) do
    if Map.get(user_, :id) != nil do
      assert user["id"] == user_.id
    else
      assert(is_binary(user["id"]))
    end

    if Map.get(user_, :discord) != nil do
      assert to_integer(user["discord"]["id"]) == user_.discord.id
    end
  end

  defp verify_currency(currency, currency_) do
    assert currency["unit"] == currency_.unit
    assert to_integer(currency["guild"]) == currency_.guild
    assert currency["name"] == currency_.name

    case Map.get(currency_, :pool_amount) do
      nil ->
        nil

      pool_amount ->
        assert to_integer(currency["pool_amount"]) == pool_amount
    end

    case Map.fetch(currency_, :total_amount) do
      {:ok, total_amount} ->
        assert currency["total_amount"] == total_amount

      :error ->
        nil
    end
  end

  test "get user1 claims with invalid token by user1", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["oauth2.register"])
    conn = get(conn, Routes.v2_claim_path(conn, :me))

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "get user1 claims", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :me))

    res = json_response(conn, 200)
    res = res |> Enum.sort(&(to_integer(&1["id"]) <= to_integer(&2["id"])))
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    assert length(res) == 3

    verify_claim(at(res, 0), %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending"
    })

    verify_claim(at(res, 1), %{
      amount: 9_999_999,
      claimant: user2,
      payer: user1,
      currency: currency,
      status: "pending"
    })

    verify_claim(at(res, 2), %{
      amount: 100,
      claimant: user1,
      payer: user1,
      currency: currency,
      status: "pending"
    })
  end

  test "get user2 claims", %{conn: conn} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :me))

    res = json_response(conn, 200)
    res = res |> Enum.sort(&(to_integer(&1["id"]) <= to_integer(&2["id"])))
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}
    assert length(res) == 2

    verify_claim(at(res, 0), %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending"
    })

    verify_claim(at(res, 1), %{
      amount: 9_999_999,
      claimant: user2,
      payer: user1,
      currency: currency,
      status: "pending"
    })
  end

  test "get user1 claim0", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(0) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending"
    })
  end

  test "get claim1 by payer", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(1) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 9_999_999,
      claimant: user2,
      payer: user1,
      currency: currency,
      status: "pending"
    })
  end

  test "get claim2 by claimant", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(2) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "approved"
    })
  end

  test "get claim3 by claimant", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(3) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "denied"
    })
  end

  test "get claim4 by claimant", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(4) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "canceled"
    })
  end

  test "get claim by payer and claimant", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(5) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    _user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 100,
      claimant: user1,
      payer: user1,
      currency: currency,
      status: "pending"
    })
  end

  test "get claim0 by payer", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(0) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending"
    })
  end

  test "get claim1 by claimant", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(1) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 9_999_999,
      claimant: user2,
      payer: user1,
      currency: currency,
      status: "pending"
    })
  end

  test "get claim2 by payer", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(2) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "approved"
    })
  end

  test "get claim3 by payer", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(3) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "denied"
    })
  end

  test "get claim4 by payer", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(4) |> elem(0)).id))

    res = json_response(conn, 200)
    user1 = %{discord: %{id: ctx.user1}}
    user2 = %{discord: %{id: ctx.user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "canceled"
    })
  end

  test "get claim5 by not related user", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user2, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(5) |> elem(0)).id))

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "not_related_user"
           }
  end

  test "get claim5 with invalid token ", %{conn: conn, claims: claims} = ctx do
    conn = set_user_auth(conn, :user, ctx.user1, ["oauth2.register"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(5) |> elem(0)).id))

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "get claim5 by invalid user", %{conn: conn, claims: claims} do
    conn = set_user_auth(conn, :user, -1, ["vc.claim"])
    conn = get(conn, Routes.v2_claim_path(conn, :get_by_id, (claims |> at(5) |> elem(0)).id))

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "not_related_user"
           }
  end

  test "patch claim0 with nothing status", %{conn: conn, claims: claims, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])
    conn = patch(conn, Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id))

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "must_supply_valid_status"
           }
  end

  test "patch claim0 with invalid status", %{conn: conn, claims: claims, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      patch(conn, Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id), %{
        "status" => "nyan!"
      })

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "must_supply_valid_status"
           }
  end

  test "approve claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "approved"}
      )

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "invalid_operator"
           }
  end

  test "approve claim by payer",
       %{conn: conn, claims: claims, user1: user1, user2: user2} = ctx do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])
    claimant = %{discord: %{id: user1}}
    payer = %{discord: %{id: user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    before_claimant =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user1,
        currency: ctx.currency
      )

    before_payer =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user2,
        currency: ctx.currency
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "approved"}
      )

    res = json_response(conn, 200)

    verify_claim(res, %{
      amount: 500,
      claimant: claimant,
      payer: payer,
      currency: currency,
      status: "approved"
    })

    after_claimant =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user1,
        currency: ctx.currency
      )

    after_payer =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: user2,
        currency: ctx.currency
      )

    assert unless(before_claimant == nil, do: before_claimant.asset.amount, else: 0) + 500 ==
             after_claimant.asset.amount

    assert after_payer == nil || before_payer.asset.amount - 500 == after_payer.asset.amount
  end

  test "approve claim by payer but not_enough_amount",
       %{conn: conn, claims: claims, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(1) |> elem(0)).id),
        %{"status" => "approved"}
      )

    res = json_response(conn, 409)
    assert res == %{"error" => "conflict", "error_info" => "not_enough_amount"}
  end

  test "deny claim by claimant", %{conn: conn, claims: claims, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "denied"}
      )

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "invalid_operator"
           }
  end

  test "deny claim by payer", %{conn: conn, claims: claims, user1: user1, user2: user2} = ctx do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "denied"}
      )

    res = json_response(conn, 200)

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "denied"
    })
  end

  test "cancel claim by claimant",
       %{conn: conn, claims: claims, user1: user1, user2: user2} = ctx do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}
    res = json_response(conn, 200)

    verify_claim(res, %{
      amount: 500,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "canceled"
    })
  end

  test "cancel claim by payer",
       %{conn: conn, claims: claims, user2: user2} do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "invalid_operator"
           }
  end

  test "approve claim by not related user",
       %{conn: conn, claims: claims} do
    conn = set_user_auth(conn, :user, -1, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "invalid_operator"
           }
  end

  test "approve approved claim",
       %{conn: conn, claims: claims, user2: user2} do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(2) |> elem(0)).id),
        %{"status" => "approved"}
      )

    assert json_response(conn, 409) == %{
             "error" => "conflict",
             "error_info" => "invalid_status"
           }
  end

  test "deny claim by not related user",
       %{conn: conn, claims: claims} do
    conn = set_user_auth(conn, :user, -1, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "invalid_operator"
           }
  end

  test "cancel claim by not related user",
       %{conn: conn, claims: claims} do
    conn = set_user_auth(conn, :user, -1, ["vc.claim"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    assert json_response(conn, 403) == %{
             "error" => "forbidden",
             "error_description" => "invalid_operator"
           }
  end

  test "approve claim with invalid token",
       %{conn: conn, claims: claims, user2: user2} do
    conn = set_user_auth(conn, :user, user2, ["vc.pay"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "deny claim with invalid token",
       %{conn: conn, claims: claims, user2: user2} do
    conn = set_user_auth(conn, :user, user2, ["vc.pay"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "cancel claim with invalid token",
       %{conn: conn, claims: claims, user2: user2} do
    conn = set_user_auth(conn, :user, user2, ["vc.pay"])

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, (claims |> at(0) |> elem(0)).id),
        %{"status" => "canceled"}
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "create claim with nothing field", %{conn: conn, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post)
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "payer_discord_id_field_is_required"
           }
  end

  test "create claim with payer_discord_id and unit", %{conn: conn, user1: user1, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{"payer_discord_id" => to_string(user1), "unit" => unit}
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "amount_field_is_required"
           }
  end

  test "create claim with payer_discord_id, unit and amount",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user2),
          "unit" => unit,
          "amount" => to_string(20)
        }
      )

    res = json_response(conn, 201)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{guild: ctx.guild, name: ctx.name, pool_amount: 500, unit: ctx.unit}

    verify_claim(res, %{
      amount: 20,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending"
    })

    assert {_, _, _, _} = VirtualCrypto.Money.get_claim_by_id(res["id"])
  end

  test "create claim with invalid payer_discord_id type", %{conn: conn, user1: user1, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => user1,
          "unit" => unit,
          "amount" => to_string(20)
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_payer_discord_id_type"
           }
  end

  test "create claim with invalid payer_discord_id value", %{conn: conn, user1: user1, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => "nyan",
          "unit" => unit,
          "amount" => to_string(20)
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_payer_discord_id_value"
           }
  end

  test "create claim with invalid payer_discord_id value2", %{
    conn: conn,
    user1: user1,
    unit: unit
  } do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => "2nyan",
          "unit" => unit,
          "amount" => to_string(20)
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_payer_discord_id_value"
           }
  end

  test "create claim with invalid amount type", %{conn: conn, user1: user1, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user1),
          "unit" => unit,
          "amount" => 20
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_amount_type"
           }
  end

  test "create claim with invalid amount value", %{conn: conn, user1: user1, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user1),
          "unit" => unit,
          "amount" => "nyan"
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_amount_value"
           }
  end

  test "create claim with invalid amount value2", %{conn: conn, user1: user1, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user1),
          "unit" => unit,
          "amount" => "2nyan"
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_amount_value"
           }
  end

  test "create claim with invalid token", %{conn: conn, user1: user1, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.pay"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user1),
          "unit" => unit,
          "amount" => to_string(20)
        }
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end
end
