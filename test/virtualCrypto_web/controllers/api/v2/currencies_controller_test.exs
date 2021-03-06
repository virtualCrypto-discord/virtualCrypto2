defmodule InfoControllerTest.V2 do
  use VirtualCryptoWeb.RestCase, async: true
  setup :setup_money

  @need_one_parameter_from_id_guild_name_or_unit %{
    "error" => "invalid_request",
    "error_description" => "need_one_parameter_from_id_guild_name_or_unit"
  }
  defp success(m) do
    %{
      "guild" => to_string(m.guild),
      "name" => m.name,
      "pool_amount" => "500",
      "total_amount" => "200500",
      "unit" => m.unit
    }
  end

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
    conn = get(conn, Routes.v2_currencies_path(conn, :index))

    assert json_response(conn, 400) == @need_one_parameter_from_id_guild_name_or_unit
  end

  test "supply invalid named parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{invalid: "x"}))

    assert json_response(conn, 400) == @need_one_parameter_from_id_guild_name_or_unit
  end

  test "supply too many parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{guild: "1", id: 1}))

    assert json_response(conn, 400) == @need_one_parameter_from_id_guild_name_or_unit
  end

  test "supply invalid guild parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{guild: "x"}))

    assert json_response(conn, 400) == @guild_id_must_be_positive_integer
  end

  test "supply invalid guild parameter2", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{guild: "-21"}))

    assert json_response(conn, 400) == @guild_id_must_be_positive_integer
  end

  test "supply no_match guild parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{guild: "123"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match guild parameter", %{conn: conn} = ctx do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{guild: ctx.guild}))

    assert json_response(conn, 200) == success(ctx)
  end

  test "supply no_match unit parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{unit: "x"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match unit parameter", %{conn: conn} = ctx do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{unit: ctx.unit}))

    assert json_response(conn, 200) == success(ctx)
  end

  test "supply no_match name parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{name: "wan"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match name parameter", %{conn: conn} = ctx do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{name: ctx.name}))

    assert json_response(conn, 200) == success(ctx)
  end

  test "supply invalid id parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{id: "x"}))

    assert json_response(conn, 400) == @id_must_be_positive_integer
  end

  test "supply invalid id parameter2", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{id: "-21"}))

    assert json_response(conn, 400) == @id_must_be_positive_integer
  end

  test "supply no_match id parameter", %{conn: conn} do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{id: "123"}))

    assert json_response(conn, 404) == @not_found
  end

  test "supply match id parameter", %{conn: conn} = ctx do
    conn = get(conn, Routes.v2_currencies_path(conn, :index, %{id: ctx.currency}))

    assert json_response(conn, 200) == success(ctx)
  end
end
