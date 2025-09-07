defmodule ContractControllerTest.V2 do
  use VirtualCryptoWeb.RestCase, async: true
  import Enum, only: [at: 2]
  import String, only: [to_integer: 1]
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  use VirtualCryptoWeb.TestDataVerifier

  setup :setup_contract

  setup %{conn: conn} = d do
    Map.put(
      d,
      :conn,
      VirtualCryptoWeb.Plug.DiscordApiService.set_service(
        conn,
        VirtualCryptoWeb.ContractTest.TestDiscordAPI
      )
    )
  end

  defp valid_contract_request(user, deposits \\ []) do
    %{"contractors" => [%{"discord_id" => to_string(user), "deposits" => deposits}]}
  end

  test "create simple contract with invalid token", %{conn: conn, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.contract"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :create),
        valid_contract_request(user1)
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "create simple contract with insufficient scope", %{conn: conn, user1: user1, app1: app1} do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :create),
        valid_contract_request(user1)
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "create contract with no agreements", %{conn: conn, user1: user1, app1: app1} do
    conn = set_user_auth(conn, :app, app1, ["vc.contract"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :create),
        valid_contract_request(user1)
      )

    user1 = to_string(user1)

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "contractor_must_have_one_or_more_agreements"
           }
  end

  test "create simple contract with invalid field", %{conn: conn, user1: user1, app1: app1} do
    conn = set_user_auth(conn, :app, app1, ["vc.contract"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :create),
        valid_contract_request(user1, [
          %{}
        ])
      )

    user1 = to_string(user1)

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "currency_unit_and_amount_is_required"
           }
  end

  test "create simple contract", %{conn: conn, user1: user1, app1: app1, unit: unit, guild: guild} do
    conn = set_user_auth(conn, :app, app1, ["vc.contract"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :create),
        valid_contract_request(user1, [
          %{
            "currency_unit" => unit,
            "deposit_amount" => 100
          }
        ])
      )

    user1 = to_string(user1)
    guild = to_string(guild)
    name = "nyan" <> guild

    assert %{
             "contractor" => [
               %{
                 "user" => %{
                   "id" => _,
                   "discord" => %{
                     "id" => ^user1
                   }
                 },
                 "deposits" => [
                   %{
                     "currency" => %{
                       "guild" => ^guild,
                       "name" => ^name,
                       "pool_amount" => "500",
                       "unit" => ^unit
                     },
                     "deposit_amount" => "100",
                     "executed_amount" => "0"
                   }
                 ],
                 "status" => "unclosed"
               }
             ],
             "created_at" => _,
             "updated_at" => _
           } = json_response(conn, 201)
  end

  test "close contract without version", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute, contract1.contract.id)
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "version_is_required"
           }
  end

  test "close contract with invalid version", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute, contract1.contract.id),
        %{"version" => "invalid"}
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_version_field"
           }
  end

  test "close contract beta1 mising action", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute, contract1.contract.id),
        %{"version" => "beta1"}
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "action_is_required"
           }
  end

  test "close contract beta1 missing action op", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute, contract1.contract.id),
        %{"version" => "beta1", "action" => %{}}
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "missing_action_op"
           }
  end

  test "close contract beta1 invalid action op", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute, contract1.contract.id),
        %{
          "version" => "beta1",
          "action" => %{
            "op" => "invalid"
          }
        }
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "invalid_action_op"
           }
  end

  test "close contract with invalid token", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute, contract1.contract.id),
        %{
          "version" => "beta1",
          "action" => %{
            "op" => "close"
          }
        }
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end

  test "close contract with valid token", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.contract"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute, contract1.contract.id),
        %{
          "version" => "beta1",
          "action" => %{
            "op" => "close"
          }
        }
      )

    assert response(conn, 204)

    # TODO: is closed?
  end
end
