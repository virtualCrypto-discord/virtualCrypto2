defmodule InteractionsControllerTest.Create do
  use VirtualCryptoWeb.InteractionsCase, async: true
  import InteractionsControllerTest.Create.Helper
  import VirtualCryptoWeb.Api.InteractionsView.Util

  setup :setup_money

  defp _encode(0) do
    []
  end

  defp _encode(v) do
    [String.at("abcdefghijklmnopqrstuvwxyz", rem(v, 26)) | _encode(div(v, 26))]
  end

  defp encode(v) do
    Enum.reverse(_encode(v)) |> Enum.join()
  end

  defp encode() do
    encode(counter())
  end

  test "valid request", ctx do
    sender = counter()
    amount = 10000
    unit = "#{encode()}"
    name = "funyu#{encode()}"

    conn =
      post_command(
        ctx.conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender)
      )

    color = color_ok()
    description = "✅ 通貨の作成に成功しました！ `/info unit: #{unit}`コマンドで通貨の情報をご覧ください。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description
                 }
               ],
               "allowed_mentions" => %{"parse" => []}
             },
             "type" => 4
           } = json_response(conn, 200)

    currency = VirtualCrypto.Repo.get_by(VirtualCrypto.Money.Currency, unit: unit)

    assert currency.name == name
    assert currency.pool_amount == div(amount + 199, 200)

    asset =
      VirtualCrypto.Money.balance(VirtualCrypto.Money.DiscordService,
        user: sender,
        currency: currency.id
      ).asset

    assert asset.amount == amount
  end

  test "prevent name conflict", ctx do
    sender = counter()
    amount = 10000
    unit = encode()
    name = ctx.name
    conn = ctx.conn

    conn =
      post_command(
        conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender, 494_780_225_280_802_818)
      )

    color = color_error()
    description = "`#{name}`という名前の通貨は存在しています。別の名前を使用してください。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description,
                   "title" => "エラー"
                 }
               ],
               "allowed_mentions" => %{"parse" => []},
               "flags" => 64
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "prevent unit conflict", ctx do
    sender = counter()
    amount = 10000
    unit = ctx.unit
    name = "funyu#{encode()}"
    conn = ctx.conn

    conn =
      post_command(
        conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender, 494_780_225_280_802_818)
      )

    color = color_error()
    description = "`#{unit}`という単位の通貨は存在しています。別の単位を使用してください。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description,
                   "title" => "エラー"
                 }
               ],
               "flags" => 64,
               "allowed_mentions" => %{"parse" => []}
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "prevent larger amount", ctx do
    sender = counter()
    amount = "9007199254740992"
    unit = encode()
    name = "funyu#{encode()}"
    conn = ctx.conn

    conn =
      post_command(
        conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender, 494_780_225_280_802_818)
      )

    color = color_error()
    description = "不正な金額です。1以上4294967295以下である必要があります。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description,
                   "title" => "エラー"
                 }
               ],
               "flags" => 64,
               "allowed_mentions" => %{"parse" => []}
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "not enough permission", ctx do
    sender = counter()
    amount = 10000
    unit = encode()
    name = "funyu#{encode()}"
    conn = ctx.conn

    conn =
      post_command(
        conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender, 494_780_225_280_802_818, 0)
      )

    color = color_error()
    description = "実行には管理者権限が必要です。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description,
                   "title" => "エラー"
                 }
               ],
               "flags" => 64,
               "allowed_mentions" => %{"parse" => []}
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "prevent created guild", ctx do
    sender = counter()
    amount = 10000
    unit = encode()
    name = "funyu#{encode()}"
    conn = ctx.conn

    conn =
      post_command(
        conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender, ctx.currency_guild)
      )

    color = color_error()
    description = "このギルドではすでに通貨が作成されています。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description,
                   "title" => "エラー"
                 }
               ],
               "flags" => 64,
               "allowed_mentions" => %{"parse" => []}
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "prevent invalid unit", ctx do
    sender = counter()
    amount = 10000
    unit = "AA"
    name = "funyu#{encode()}"
    conn = ctx.conn

    conn =
      post_command(
        conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender)
      )

    color = color_error()
    description = "通貨の名前は2から16文字以内の英数字、単位は1から10文字以内の英小文字を使ってください。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description,
                   "title" => "エラー"
                 }
               ],
               "flags" => 64,
               "allowed_mentions" => %{"parse" => []}
             },
             "type" => 4
           } = json_response(conn, 200)
  end

  test "prevent invalid name", ctx do
    sender = counter()
    amount = 10000
    unit = "a"
    name = " "
    conn = ctx.conn

    conn =
      post_command(
        conn,
        from_guild(%{amount: amount, unit: unit, name: name}, sender)
      )

    color = color_error()
    description = "通貨の名前は2から16文字以内の英数字、単位は1から10文字以内の英小文字を使ってください。"

    assert %{
             "data" => %{
               "embeds" => [
                 %{
                   "color" => ^color,
                   "description" => ^description,
                   "title" => "エラー"
                 }
               ],
               "flags" => 64,
               "allowed_mentions" => %{"parse" => []}
             },
             "type" => 4
           } = json_response(conn, 200)
  end
end
