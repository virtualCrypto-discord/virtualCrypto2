defmodule VirtualCryptoWeb.CommandHandler do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Money.DiscordService
  alias VirtualCryptoWeb.JsonUtil
  @moduledoc false
  @bot_invite_url Application.get_env(:virtualCrypto, :invite_url)
  @guild_invite_url Application.get_env(:virtualCrypto, :support_guild_invite_url)
  @site_url Application.get_env(:virtualCrypto, :site_url)

  def name_unit_check(name, unit) do
    with true <- Regex.match?(~r/[a-zA-Z0-9]{2,16}/, name),
         Regex.match?(~r/[a-z]{1,10}/, unit) do
      true
    else
      _ -> false
    end
  end

  def handle("bal", _options, %{
        "member" => %{"user" => %{"id" => executor}}
      }) do
    int_executor = String.to_integer(executor)
    Money.balance(DiscordService, user: int_executor)
  end

  def handle("pay", %{"unit" => unit, "user" => receiver, "amount" => amount}, %{
        "member" => %{"user" => %{"id" => sender}}
      }) do
    int_receiver = String.to_integer(receiver)
    int_sender = String.to_integer(sender)
    # support to over 2^53-1(INTEGER_MAX_SAFE_VALUE)
    int_amount = JsonUtil.to_integer(amount)

    case Money.pay(
           DiscordService,
           sender: int_sender,
           receiver: int_receiver,
           amount: int_amount,
           unit: unit
         ) do
      {:ok} -> {:ok, %{unit: unit, receiver: receiver, sender: sender, amount: int_amount}}
      {:error, v} -> {:error, v}
    end
  end

  def handle("give", %{"user" => receiver, "amount" => amount}, %{
        "guild_id" => guild,
        "member" => %{"permissions" => perms}
      }) do
    int_permissions = String.to_integer(perms)
    # support to over 2^53-1(INTEGER_MAX_SAFE_VALUE)
    int_amount = JsonUtil.to_integer(amount)

    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      int_receiver = String.to_integer(receiver)
      int_guild = String.to_integer(guild)

      case VirtualCrypto.Money.give(receiver: int_receiver, amount: int_amount, guild: int_guild) do
        {:ok, %VirtualCrypto.Money.Info{unit: unit}} -> {:ok, {receiver, int_amount, unit}}
        {:error, v} -> {:error, v}
      end
    else
      {:error, :permission}
    end
  end

  def handle("create", options, %{"guild_id" => guild_id, "member" => %{"user" => user}} = params) do
    int_guild_id = String.to_integer(guild_id)
    int_user_id = String.to_integer(user["id"])
    int_permissions = String.to_integer(params["member"]["permissions"])

    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      if name_unit_check(options["name"], options["unit"]) do
        case VirtualCrypto.Money.create(
               guild: int_guild_id,
               name: options["name"],
               unit: options["unit"],
               creator: int_user_id,
               # support to over 2^53-1(INTEGER_MAX_SAFE_VALUE)
               creator_amount: JsonUtil.to_integer(options["amount"])
             ) do
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

  def handle("info", options, %{"guild_id" => guild_id, "member" => %{"user" => user}}) do
    int_user_id = String.to_integer(user["id"])

    case VirtualCrypto.Money.info(name: options["name"], unit: options["unit"], guild: guild_id) do
      nil ->
        {:error, nil, nil, nil}

      info ->
        case Money.balance(DiscordService, user: int_user_id)
             |> Enum.filter(fn x -> x.unit == info.unit end) do
          [balance] -> {:ok, info, balance.amount, Discord.Api.V8.get_guild(info.guild)}
          [] -> {:ok, info, 0, Discord.Api.V8.get_guild(info.guild)}
        end
    end
  end

  def handle("help", _options, _params) do
    {@bot_invite_url, @guild_invite_url, @site_url}
  end

  def handle("invite", _, _) do
    {@bot_invite_url, @guild_invite_url}
  end

  def handle(
        "claim",
        %{"subcommand" => "list"},
        %{"member" => %{"user" => user}}
      ) do
    int_user_id = String.to_integer(user["id"])
    {sent_claims, received_claims} = Money.get_pending_claims(DiscordService, int_user_id)
    {:ok, "list", Enum.slice(sent_claims, 0, 10), Enum.slice(received_claims, 0, 10)}
  end

  def handle(
        "claim",
        %{"subcommand" => "make"} = options,
        %{"member" => %{"user" => user}}
      ) do
    int_payer_id = options["sub_options"]["user"] |> String.to_integer()
    int_user_id = user["id"] |> String.to_integer()
    int_amount = options["sub_options"]["amount"] |> JsonUtil.to_integer()

    case Money.create_claim(
           DiscordService,
           int_user_id,
           int_payer_id,
           options["sub_options"]["unit"],
           int_amount
         ) do
      {:ok, claim} -> {:ok, "make", claim}
      {:error, :money_not_found} -> {:error, "make", :money_not_found}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "approve"} = options,
        %{"member" => %{"user" => user}}
      ) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"] |> String.to_integer()

    case Money.approve_claim(DiscordService, id, int_user_id) do
      {:ok, claim} -> {:ok, "approve", claim}
      {:error, err} -> {:error, "approve", err}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "deny"} = options,
        %{"member" => %{"user" => user}}
      ) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"] |> String.to_integer()

    case Money.deny_claim(DiscordService, id, int_user_id) do
      {:ok, claim} -> {:ok, "deny", claim}
      {:error, err} -> {:error, "deny", err}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "cancel"} = options,
        %{"member" => %{"user" => user}}
      ) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"] |> String.to_integer()

    case Money.cancel_claim(DiscordService, id, int_user_id) do
      {:ok, claim} -> {:ok, "cancel", claim}
      {:error, err} -> {:error, "cancel", err}
    end
  end

  def handle(_, _, _) do
  end
end
