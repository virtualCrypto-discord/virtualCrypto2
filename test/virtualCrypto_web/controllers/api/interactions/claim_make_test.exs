defmodule InteractionsControllerTest.Claim.Make do
  use VirtualCryptoWeb.InteractionsCase, async: true
  test "make valid claim", %{conn: conn} do
    conn =
      post(
        conn,
        Routes.interactions_path(conn, :index)
      )
  end
end
