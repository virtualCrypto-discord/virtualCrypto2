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

  test "create simple contract", %{conn: conn, user1: user1} do
    conn = set_user_auth(conn, :user, user1, ["vc.contract"])

    conn =
      post(
        conn,
        Routes.v2_contract_path(conn, :post)
      )

    assert json_response(conn, 400) == %{
             "error" => "invalid_request",
             "error_description" => "payer_discord_id_field_is_required"
           }
  end
end
