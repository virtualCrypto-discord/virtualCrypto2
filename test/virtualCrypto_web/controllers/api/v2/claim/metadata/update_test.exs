defmodule ClaimControllerTest.Metadata.Update.V2 do
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

  test "create claim with metadata",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user2),
          "unit" => unit,
          "amount" => to_string(20),
          "metadata" => %{
            "a" => "b"
          }
        }
      )

    res = json_response(conn, 201)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: 20,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{
        "a" => "b"
      }
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])
  end

  test "insert claim metadata",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        %{}
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => %{
            "a" => "b"
          }
        }
      )

    res = json_response(conn, 200)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{
        "a" => "b"
      }
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])
  end

  test "upsert claim metadata",
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
          "e" => "f",
          "d" => "xxx"
        }
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => %{
            "a" => "c",
            "x" => "y",
            "d" => nil
          }
        }
      )

    res = json_response(conn, 200)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{
        "e" => "f",
        "a" => "c",
        "x" => "y"
      }
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])
  end

  test "delete claim metadata",
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
          "d" => "xxx"
        }
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => nil
        }
      )

    res = json_response(conn, 200)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{}
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])
  end

  test "delete claim metadata if empty",
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
          "d" => "xxx"
        }
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => %{
            "d" => nil
          }
        }
      )

    res = json_response(conn, 200)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{}
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])
  end

  test "prevent not related user",
       %{conn: conn, user1: user1, user2: user2, unit: unit} do
    conn = set_user_auth(conn, :user, -1, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        %{
          "d" => "xxx"
        }
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => %{
            "d" => nil
          }
        }
      )

    res = json_response(conn, 403)
    assert res == %{"error" => "forbidden", "error_description" => "invalid_operator"}
  end

  test "not seeing other user metadata",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        %{
          "owner" => "user1"
        }
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => %{
            "owner_" => "user2"
          }
        }
      )

    res = json_response(conn, 200)
    user1 = %{discord: %{id: user1}}
    user2 = %{discord: %{id: user2}}
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: user1,
      payer: user2,
      currency: currency,
      status: "pending",
      metadata: %{"owner_" => "user2"}
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])
  end

  test "approve with metadata",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        %{
          "owner" => "user1"
        }
      )

    before_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    before_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "status" => "approved",
          "metadata" => %{
            "transaction_id" => "abcd1234"
          }
        }
      )

    res = json_response(conn, 200)
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: %{discord: %{id: user1}},
      payer: %{discord: %{id: user2}},
      currency: currency,
      status: "approved",
      metadata: %{"transaction_id" => "abcd1234"}
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])

    after_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    after_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    assert unless(before_claimant == nil, do: before_claimant.asset.amount, else: 0) + amount ==
             after_claimant.asset.amount

    assert after_payer == nil || before_payer.asset.amount - amount == after_payer.asset.amount
  end

  test "upsert metadata with status update",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        %{
          "owner" => "user1"
        }
      )

    {:ok, _} =
      VirtualCrypto.Money.update_metadata(id, %DiscordUser{id: user2}, %{
        "data" => "27",
        "pending_data" => "xxxx"
      })

    before_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    before_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "status" => "approved",
          "metadata" => %{
            "transaction_id" => "abcd1234",
            "pending_data" => nil
          }
        }
      )

    res = json_response(conn, 200)
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: %{discord: %{id: user1}},
      payer: %{discord: %{id: user2}},
      currency: currency,
      status: "approved",
      metadata: %{"data" => "27", "transaction_id" => "abcd1234"}
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])

    after_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    after_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    assert unless(before_claimant == nil, do: before_claimant.asset.amount, else: 0) + amount ==
             after_claimant.asset.amount

    assert after_payer == nil || before_payer.asset.amount - amount == after_payer.asset.amount
  end

  test "deny with metadata",
       %{conn: conn, user1: user1, user2: user2, unit: unit} = ctx do
    conn = set_user_auth(conn, :user, user2, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        %{
          "owner" => "user1"
        }
      )

    before_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    before_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "status" => "denied",
          "metadata" => %{
            "transaction_id" => "abcd1234"
          }
        }
      )

    res = json_response(conn, 200)
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: %{discord: %{id: user1}},
      payer: %{discord: %{id: user2}},
      currency: currency,
      status: "denied",
      metadata: %{"transaction_id" => "abcd1234"}
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])

    after_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    after_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    assert unless(before_claimant == nil, do: before_claimant.asset.amount, else: 0) ==
             after_claimant.asset.amount

    assert after_payer == nil || before_payer.asset.amount == after_payer.asset.amount
  end

  test "cancel with metadata",
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
          "owner" => "user1"
        }
      )

    before_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    before_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "status" => "canceled",
          "metadata" => %{
            "transaction_id" => "abcd1234"
          }
        }
      )

    res = json_response(conn, 200)
    currency = %{name: ctx.name, unit: ctx.unit}

    verify_claim(res, %{
      amount: amount,
      claimant: %{discord: %{id: user1}},
      payer: %{discord: %{id: user2}},
      currency: currency,
      status: "canceled",
      metadata: %{"owner" => "user1", "transaction_id" => "abcd1234"}
    })

    assert %{} = VirtualCrypto.Money.Query.Claim.get_claim_by_id(res["id"])

    after_claimant =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user1},
        currency: ctx.currency
      )

    after_payer =
      VirtualCrypto.Money.balance(
        user: %DiscordUser{id: user2},
        currency: ctx.currency
      )

    assert unless(before_claimant == nil, do: before_claimant.asset.amount, else: 0) ==
             after_claimant.asset.amount

    assert after_payer == nil || before_payer.asset.amount == after_payer.asset.amount
  end

  # https://stripe.com/docs/api/metadata
  test "prevent over per entry limitation in create", %{
    conn: conn,
    user1: user1,
    user2: user2,
    unit: unit
  } do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user2),
          "unit" => unit,
          "amount" => to_string(20),
          "metadata" => %{
            String.duplicate("b", 41) => "x",
            "x" => String.duplicate("b", 501)
          }
        }
      )

    res = json_response(conn, 400)

    assert %{
             "error" => "invalid_request",
             "error_description" => "invalid_metadata",
             "error_description_details" => [
               "too large(max: 40) metadata key(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb...)",
               "too large metadata value(max: 500) at x(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb...)"
             ]
           } == res
  end

  test "prevent over per entry limitation in update",
       %{conn: conn, user1: user1, user2: user2, unit: unit} do
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
          "e" => "f",
          "d" => "xxx"
        }
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => %{
            String.duplicate("x", 41) => "c",
            "x" => String.duplicate("b", 501),
            "d" => nil
          }
        }
      )

    res = json_response(conn, 400)

    assert %{
             "error" => "invalid_request",
             "error_description" => "invalid_metadata",
             "error_description_details" => [
               "too large metadata value(max: 500) at x(bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb...)",
               "too large(max: 40) metadata key(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx...)"
             ]
           } == res
  end

  test "prevent over number of entry limitation in create", %{
    conn: conn,
    user1: user1,
    user2: user2,
    unit: unit
  } do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_claim_path(conn, :post),
        %{
          "payer_discord_id" => to_string(user2),
          "unit" => unit,
          "amount" => to_string(20),
          "metadata" => 1..51 |> Enum.map(&to_string/1) |> Enum.map(&{&1, &1}) |> Map.new()
        }
      )

    res = json_response(conn, 400)

    assert %{
             "error" => "invalid_request",
             "error_description" => "invalid_metadata",
             "error_description_details" => ["too many entries in metadata(max: 50)"]
           } == res
  end

  test "prevent over number of entry limitation in update",
       %{conn: conn, user1: user1, user2: user2, unit: unit} do
    conn = set_user_auth(conn, :user, user1, ["vc.claim"])
    amount = 40

    {:ok, %{claim: %{id: id}}} =
      VirtualCrypto.Money.create_claim(
        %DiscordUser{id: user1},
        %DiscordUser{id: user2},
        unit,
        amount,
        1..50 |> Enum.map(&to_string/1) |> Enum.map(&{&1, &1}) |> Map.new()
      )

    conn =
      patch(
        conn,
        Routes.v2_claim_path(conn, :patch, id),
        %{
          "id" => id,
          "metadata" => %{
            "51" => "51"
          }
        }
      )

    res = json_response(conn, 400)

    assert %{
             "error" => "invalid_request",
             "error_description" =>
               "The upper limit of the number of metadata is 50, and it is highly possible that this has been reached. (Maybe for other reasons)"
           } == res
  end
end
