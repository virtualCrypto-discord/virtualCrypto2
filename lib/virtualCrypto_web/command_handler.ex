defmodule VirtualCryptoWeb.CommandHandler do
  @moduledoc false
  @bot_invite_url Application.get_env(:virtualCrypto, :invite_url)
  @guild_invite_url Application.get_env(:virtualCrypto, :support_guild_invite_url)
  @site_url Application.get_env(:virtualCrypto, :site_url)

  def name_unit_check(name, unit) do
    with true <- Regex.match?(~r/[a-zA-Z0-9]{2,16}/, name),
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

  def handle("info", options, %{ "guild_id" => guild_id, "member" => %{"user" => user} } = params) do
    int_user_id = String.to_integer user["id"]
    case VirtualCrypto.Money.info name: options["name"], unit: options["unit"], guild: guild_id do
      nil -> {:error, nil, nil, options}
      info ->
        balance =
          VirtualCrypto.Money.balance(user: int_user_id)
          |> Enum.filter(fn x -> x.unit == info.unit end)
          |> hd
        {:ok, info, balance.amount, Discord.Api.V8.get_guild(guild_id), options}
    end
  end

  def handle("help", options, params) do
    {@bot_invite_url, @guild_invite_url, @site_url}
  end

  def handle("invite", _, _) do
    {@bot_invite_url, @guild_invite_url}
  end

  def handle("claim", %{"subcommand" => "list"} = options, %{"member" => %{"user" => user}} = params) do
    int_user_id = String.to_integer(user["id"])
    {sent_claims, received_claims} = VirtualCrypto.Money.get_pending_claims(int_user_id)
    {:ok, "list", Enum.slice(sent_claims, 0, 10), Enum.slice(received_claims, 0, 10)}
  end

  def handle("claim", %{"subcommand" => "make"} = options, %{"member" => %{"user" => user}} = params) do
    int_payer_id = options["sub_options"]["user"] |> String.to_integer
    int_user_id = user["id"] |> String.to_integer
    {:ok, claim} = VirtualCrypto.Money.create_claim(int_user_id, int_payer_id, options["sub_options"]["unit"], options["sub_options"]["amount"], (if options["sub_options"]["message"], do: options["sub_options"]["message"], else: ""))
    {:ok, "make", claim}
  end

  def handle("claim", %{"subcommand" => "approve"} = options, %{"member" => %{"user" => user}} = params) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"]
    case VirtualCrypto.Money.approve_claim(id, int_user_id) do
      {:ok} -> {:ok, "approve", VirtualCrypto.Money.InternalAction.get_claim_by_id(id)}
      {:error, err} -> {:error, "approve", err}
    end
  end

  def handle("claim", %{"subcommand" => "deny"} = options, %{"member" => %{"user" => user}} = params) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"]
    case VirtualCrypto.Money.deny_claim(id, int_user_id) do
      {:ok} -> {:ok, "deny", VirtualCrypto.Money.InternalAction.get_claim_by_id(id)}
      {:error, err} -> {:error, "deny", err}
    end
  end

  def handle("claim", %{"subcommand" => "cancel"} = options, %{"member" => %{"user" => user}} = params) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"]
    case VirtualCrypto.Money.cancel_claim(id, int_user_id) do
      {:ok} -> {:ok, "cancel", VirtualCrypto.Money.InternalAction.get_claim_by_id(id)}
      {:error, err} -> {:error, "cancel", err}
    end
  end

  def handle _, _, _ do
  end
end
