defmodule VirtualCryptoWeb.CommandHandler do
  @moduledoc false
  @bot_invite_url "https://discord.com/api/oauth2/authorize?client_id=754196279315398666&permissions=379968&scope=applications.commands%20bot"
  @guild_invite_url "https://discord.gg/Hgp5DpG"

  def name_unit_check(name, unit) do
    with true <- Regex.match?(~r/[a-zA-Z0-9]{2,32}/, name),
      Regex.match?(~r/[a-z]{1,10}/, unit)
      do true
    else
      _ -> false
    end
  end

  def handle("bal",_options, %{
    "member" => %{"user" => %{"id" => executor}}
  }) do
    int_executor = String.to_integer(executor)
    VirtualCrypto.Money.balance(user: int_executor)
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
    "guild_id" => guild,
    "member" => %{"permissions" => perms}
  }) do
    int_permissions = String.to_integer perms
    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      int_receiver = String.to_integer receiver
      int_guild = String.to_integer  guild
      case VirtualCrypto.Money.give(receiver: int_receiver,amount: amount,guild: int_guild) do
        {:ok,%VirtualCrypto.Money.Info{unit: unit}} -> {:ok, {receiver,amount,unit}}
        {:error, v } -> {:error, v}
      end
    else
      {:error, :permission}
    end

  end

  def handle("create", options, %{ "guild_id" => guild_id, "member" => %{"user" => user} } = params) do
    int_guild_id = String.to_integer guild_id
    int_user_id = String.to_integer user["id"]
    int_permissions = String.to_integer params["member"]["permissions"]

    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      if name_unit_check(options["name"], options["unit"]) do
        case VirtualCrypto.Money.create(
               guild: int_guild_id,
               name: options["name"],
               unit: options["unit"],
               creator: int_user_id,
               creator_amount: options["amount"]) do
          {:ok} -> {:ok, :ok, options}
          {:error, :guild} -> {:error, :guild, options}
          {:error, :unit} -> {:error, :unit, options}
          {:error, :name} -> {:error, :name, options}
          _ -> {:error, :none, options}
        end
      else
        {:error, :invalid, options}
      end
    else
      {:error, :permission, options}
    end
  end

  def handle("info", options, %{ "guild_id" => guild_id } = params) do
    case VirtualCrypto.Money.info name: options["name"], unit: options["unit"], guild: guild_id do
      nil -> {:error, nil, nil, options}
      info -> {:ok, info, Discord.Api.V8.get_guild(guild_id), options}
    end
  end

  def handle("help", options, params) do
  end

  def handle("invite", _, _) do
    {@bot_invite_url, @guild_invite_url}
  end

  def handle(_, options, params) do
  end
end
