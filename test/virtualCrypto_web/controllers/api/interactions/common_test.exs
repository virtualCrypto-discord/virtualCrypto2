defmodule InteractionsControllerTest.Claim.Common do
  use VirtualCryptoWeb.InteractionsCase, async: true

  test "nothing body nor header", %{conn: conn} do
    conn =
      post(
        conn,
        Routes.interactions_path(conn, :index)
      )

    assert response(conn, 401) == "invalid request signature"
  end

  test "nothing type field", %{conn: conn} do
    conn =
      post_command(
        conn,
        %{}
      )

    assert response(conn, 400) == "Type Not Found"
  end

  test "type be string", %{conn: conn} do
    conn =
      post_command(
        conn,
        %{type: "1"}
      )

    assert response(conn, 400) == "Type Not Found"
  end

  test "type be nil", %{conn: conn} do
    conn =
      post_command(
        conn,
        %{type: nil}
      )

    assert response(conn, 400) == "Type Not Found"
  end

  test "type be ping", %{conn: conn} do
    conn =
      post_command(
        conn,
        %{"type" => 1}
      )

    assert json_response(conn, 200) == %{"type" => 1}
  end

  test "out of range type", %{conn: conn} do
    conn =
      post_command(
        conn,
        %{"type" => -21}
      )

    assert response(conn, 400) == "Type Not Found"
  end
end
