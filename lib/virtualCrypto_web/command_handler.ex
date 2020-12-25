defmodule VirtualCryptoWeb.CommandHandler do
  @moduledoc false

  def name_unit_check(name, unit) do
    with true <- Regex.match?(~r/[a-zA-Z0-9]{2,32}/, name),
      Regex.match?(~r/[a-zA-Z0-9]{1,10}/, unit)
      do true
    else
      _ -> false
    end
  end

  def handle("bal",options, params) do

  end

  def handle("pay", %{"unit" => unit, "user" => receiver, "amount" => amount}, %{
        "member" => %{"user" => %{"id" => sender}}
      }) do
    int_receiver = String.to_integer(receiver)
    int_sender = String.to_integer(sender)
    case VirtualCrypto.Money.pay(sender: int_sender,receiver: int_receiver,amount: amount, unit: unit) do
      {:ok } -> {:ok,%{unit: unit,receiver: receiver,sender: sender, amount: amount}}
      {:error, v } -> {:error, v}
    end
  end

  def handle("give", %{"user" => receiver, "amount" => amount}, %{
    "guild_id" => guild
  }) do
    int_receiver = String.to_integer receiver
    int_guild = String.to_integer  guild
    case VirtualCrypto.Money.give(receiver: int_receiver,amount: amount,guild: int_guild) do
      {:ok,%VirtualCrypto.Money.Info{unit: unit}} -> {:ok, {receiver,amount,unit}}
      {:error, v } -> {:error, v}
    end
  end

  def handle("create", options, %{ "guild_id" => guild_id } = params) do
    {int_guild_id, _} = Integer.parse guild_id
    {int_permissions, _} = Integer.parse params["member"]["permissions"]
    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      if name_unit_check(options["name"], options["unit"]) do
        case VirtualCrypto.Money.create(guild: int_guild_id, name: options["name"], unit: options["unit"]) do
          {:ok} -> {:ok, "通貨の作成に成功しました！ `/info " <> options["unit"] <> "`コマンドで通貨の情報をご覧ください。"}
          {:error, :guild} -> {:error, "このギルドではすでに通貨が作成されています。"}
          {:error, :unit} -> {:error, options["unit"] <> "という単位の通貨は存在しています。別の名前を使用してください。"}
          {:error, :name} -> {:error, options["name"] <> "という名前の通貨は存在しています。別の名前を使用してください。"}
          _ -> {:error, "不明なエラーが発生しました。時間を開けてもう一度実行してください。"}
        end
      else
        {:error, "通貨の名前は2から32文字以内の英数字、単位は1から10文字以内の英数字を使ってください。"}
      end
    else
      {:error, "実行には管理者権限が必要です。"}
    end
  end
  def handle("create", options, params) do
  end

  def handle("info", options, params) do
  end

  def handle("help", options, params) do
  end

  def handle("invite", options, params) do
  end

  def handle(_, options, params) do
  end
end
