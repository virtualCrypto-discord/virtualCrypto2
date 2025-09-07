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

  defp valid_contract_request(user) do
    %{"contractors" => [%{"discord_id" => to_string(user), "deposits" => []}]}
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

  test "create simple contract", %{conn: conn, user1: user1, app1: app1} do
    conn = set_user_auth(conn, :app, app1, ["vc.contract"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :create),
        valid_contract_request(user1)
      )

    user1 = to_string(user1)

    assert %{
             "contractor" => [
               %{
                 "user" => %{
                   "id" => _,
                   "discord" => %{
                     "id" => ^user1
                   }
                 },
                 "deposits" => []
               }
             ],
             "created_at" => _,
             "updated_at" => _
           } = json_response(conn, 201)
  end

  test "close contract", %{
    conn: conn,
    user1: user1,
    app1: app1,
    contracts: %{contract1: contract1}
  } do
    conn = set_user_auth(conn, :app, app1, ["vc.claim"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :execute,contract1.contract.id),
        valid_contract_request(user1)
      )

    assert json_response(conn, 403) == %{
             "error" => "invalid_token",
             "error_description" => "permission_denied"
           }
  end
end
