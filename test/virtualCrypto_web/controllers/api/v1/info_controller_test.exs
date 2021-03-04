defmodule InfoControllerTest do
  use VirtualCryptoWeb.ConnCase, async: true
  alias VirtualCrypto.Repo
  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  setup do

    Repo.insert!(%VirtualCrypto.Money.Info{
      guild_id: 1,
      id: 1,
      name: "nyan",
      pool_amount: 1000,
      unit: "n",
      status: 0
    })

    Repo.insert!(%VirtualCrypto.Money.Info{
      guild_id: 2,
      id: 2,
      name: "wan",
      pool_amount: 10000,
      unit: "w",
      status: 0
    })

    :ok
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index))
    assert json_response(conn, 200)["data"] == []
  end
end
