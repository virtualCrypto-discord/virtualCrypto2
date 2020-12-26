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
    int_guild_id = String.to_integer guild_id
    int_permissions = String.to_integer params["member"]["permissions"]

    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      if name_unit_check(options["name"], options["unit"]) do
        case VirtualCrypto.Money.create(guild: int_guild_id, name: options["name"], unit: options["unit"]) do
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

  def handle("info", options, params) do
  end

  def handle("help", options, params) do
  end

  def handle("invite", options, params) do
  end

  def handle(_, options, params) do
  end
end
