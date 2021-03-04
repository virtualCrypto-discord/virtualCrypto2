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
      pool_amount: 500,
      unit: "n",
      status: 0
    })

    Repo.insert!(%VirtualCrypto.User.User{
      id: 1,
      discord_id: 1
    })

    Repo.insert!(%VirtualCrypto.Money.Asset{
      amount: 1000 * 200 - 500,
      user_id: 1,
      money_id: 1
    })

    Repo.insert!(%VirtualCrypto.User.User{
      id: 2,
      discord_id: 2
    })

    Repo.insert!(%VirtualCrypto.Money.Asset{
      amount: 1000,
      user_id: 2,
      money_id: 1
    })

    :ok
  end

  @need_one_parameter_from_id_guild_name_or_unit %{
    "error" => "invalid_request",
    "error_description" => "need_one_parameter_from_id_guild_name_or_unit"
  }
  @success %{
    "guild" => "1",
    "name" => "nyan",
    "pool_amount" => "500",
    "total_amount" => "200500",
    "unit" => "n"
  }
  @not_found %{
    "error" => "not_found",
    "error_description" => "not_found"
  }
  @id_must_be_positive_integer %{
    "error" => "invalid_request",
    "error_description" => "id_must_be_positive_integer"
  }
  @guild_id_must_be_positive_integer %{
    "error" => "invalid_request",
    "error_description" => "guild_id_must_be_positive_integer"
  }
  test "not supply parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index))

    assert json_response(conn, 400) == @need_one_parameter_from_id_guild_name_or_unit
  end

  test "supply invalid named parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{invalid: "x"}))

    assert json_response(conn, 400) == @need_one_parameter_from_id_guild_name_or_unit
  end

  test "supply too many parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{guild: "1", id: 1}))

    assert json_response(conn, 400) == @need_one_parameter_from_id_guild_name_or_unit
  end

  test "supply invalid guild parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{guild: "x"}))

    assert json_response(conn, 400) == @guild_id_must_be_positive_integer
  end

  test "supply invalid guild parameter2", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{guild: "-21"}))

    assert json_response(conn, 400) == @guild_id_must_be_positive_integer
  end

  test "supply no_match guild parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{guild: "123"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match guild parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{guild: "1"}))

    assert json_response(conn, 200) == @success
  end

  test "supply no_match unit parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{unit: "x"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match unit parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{unit: "n"}))

    assert json_response(conn, 200) == @success
  end

  test "supply no_match name parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{name: "wan"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match name parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{name: "nyan"}))

    assert json_response(conn, 200) == @success
  end

  test "supply invalid id parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{id: "x"}))

    assert json_response(conn, 400) == @id_must_be_positive_integer
  end

  test "supply invalid id parameter2", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{id: "-21"}))

    assert json_response(conn, 400) == @id_must_be_positive_integer
  end

  test "supply no_match id parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{id: "123"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match id parameter", %{conn: conn} do
    conn = get(conn, Routes.info_path(conn, :index, %{id: "1"}))

    assert json_response(conn, 200) == @success
  end
end
