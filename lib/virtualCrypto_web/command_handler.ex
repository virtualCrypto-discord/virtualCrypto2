defmodule VirtualCryptoWeb.CommandHandler do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Money.DiscordService

  #NOTE: https://github.com/virtualCrypto-discord/virtualCrypto2/issues/167
  defp cast_int(v) when is_binary(v) do
    String.to_integer(v)
  end

  defp cast_int(v) when is_integer(v) do
    v
  end

  defp cast_int(v) do
    v
  end

  @moduledoc false
  @bot_invite_url Application.get_env(:virtualCrypto, :invite_url)
  @guild_invite_url Application.get_env(:virtualCrypto, :support_guild_invite_url)
  @site_url Application.get_env(:virtualCrypto, :site_url)
  defp logo_url,
    do: @site_url <> "/static" <> VirtualCryptoWeb.Endpoint.static_path("/images/logo.jpg")

  def name_unit_check(name, unit) do
    with true <- Regex.match?(~r/[a-zA-Z0-9]{2,16}/, name),
         true <- Regex.match?(~r/[a-z]{1,10}/, unit) do
      true
    else
      _ -> false
    end
  end

  def handle(
        "bal",
        _options,
        %{
          "member" => %{"user" => %{"id" => executor}}
        },
        _conn
      ) do
    int_executor = String.to_integer(executor)
    Money.balance(DiscordService, user: int_executor)
  end

  def handle(
        "pay",
        %{"unit" => unit, "user" => receiver, "amount" => amount},
        %{
          "member" => %{"user" => %{"id" => sender}}
        },
        _conn
      ) do
    int_receiver = String.to_integer(receiver)
    int_sender = String.to_integer(sender)

    case Money.pay(
           DiscordService,
           sender: int_sender,
           receiver: int_receiver,
           amount: cast_int(amount),
           unit: unit
         ) do
      {:ok} -> {:ok, %{unit: unit, receiver: receiver, sender: sender, amount: amount}}
      {:error, v} -> {:error, v}
    end
  end

  def handle(
        "give",
        %{"user" => receiver, "amount" => amount},
        %{
          "guild_id" => guild,
          "member" => %{"permissions" => perms}
        },
        _conn
      ) do
    int_permissions = String.to_integer(perms)

    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      int_receiver = String.to_integer(receiver)
      int_guild = String.to_integer(guild)
      int_amount = cast_int(amount)

      case VirtualCrypto.Money.give(receiver: int_receiver, amount: int_amount, guild: int_guild) do
        {:ok,
         %{
           currency: %VirtualCrypto.Money.Info{unit: unit, pool_amount: pool_amount},
           amount: int_amount
         }} ->
          {:ok, {receiver, int_amount, unit, pool_amount}}

        {:error, v} ->
          {:error, v}
      end
    else
      {:error, :permission}
    end
  end

  def handle(
        "give",
        %{"user" => _receiver} = m,
        ctx,
        conn
      ) do
    handle("give", Map.merge(%{"amount" => :all}, m), ctx, conn)
  end

  def handle(
        "create",
        options,
        %{"guild_id" => guild_id, "member" => %{"user" => user}} = params,
        _conn
      ) do
    int_guild_id = String.to_integer(guild_id)
    int_user_id = String.to_integer(user["id"])
    int_permissions = String.to_integer(params["member"]["permissions"])
    options = %{options | "amount" => cast_int(options["amount"])}

    if Discord.Permissions.check(int_permissions, Discord.Permissions.administrator()) do
      if name_unit_check(options["name"], options["unit"]) do
        case VirtualCrypto.Money.create(
               guild: int_guild_id,
               name: options["name"],
               unit: options["unit"],
               creator: int_user_id,
               creator_amount: options["amount"]
             ) do
          {:ok} -> {:ok, :ok, options}
          {:error, :guild} -> {:error, :guild, options}
          {:error, :unit} -> {:error, :unit, options}
          {:error, :name} -> {:error, :name, options}
          {:error, :invalid_amount} -> {:error, :invalid_amount, options}
          _ -> {:error, :none, options}
        end
      else
        {:error, :invalid, options}
      end
    else
      {:error, :permission, options}
    end
  end

  def handle("info", options, %{"guild_id" => guild_id, "member" => %{"user" => user}}, _conn) do
    int_user_id = String.to_integer(user["id"])

    case VirtualCrypto.Money.info(name: options["name"], unit: options["unit"], guild: guild_id) do
      nil ->
        {:error, nil, nil, nil}

      info ->
        case Money.balance(DiscordService, user: int_user_id)
             |> Enum.filter(fn x -> x.currency.unit == info.unit end) do
          [balance] -> {:ok, info, balance.asset.amount, Discord.Api.V8.Raw.get_guild(info.guild)}
          [] -> {:ok, info, 0, Discord.Api.V8.Raw.get_guild(info.guild)}
        end
    end
  end

  def handle("help", _options, _params, _conn) do
    {logo_url(), @bot_invite_url, @guild_invite_url, @site_url}
  end

  def handle("invite", _, _, _conn) do
    {logo_url(), @bot_invite_url, @guild_invite_url}
  end

  def handle(
        "claim",
        %{"subcommand" => "list"},
        %{"member" => %{"user" => user}},
        _conn
      ) do
    int_user_id = String.to_integer(user["id"])

    {sent_claims, received_claims} =
      Money.get_claims(DiscordService, int_user_id, "pending")
      |> Enum.reduce({[], []}, fn {_claim, _info, claimant, payer} = d, {sent, received} ->
        {
          if(claimant.discord_id == int_user_id,
            do: [d | sent],
            else: sent
          ),
          if(payer.discord_id == int_user_id,
            do: [d | received],
            else: received
          )
        }
      end)

    {:ok, "list",
     Enum.slice(sent_claims |> Enum.sort(&(elem(&1, 0).id <= elem(&2, 0).id)), 0, 10),
     Enum.slice(received_claims |> Enum.sort(&(elem(&1, 0).id <= elem(&2, 0).id)), 0, 10)}
  end

  def handle(
        "claim",
        %{"subcommand" => "make"} = options,
        %{"member" => %{"user" => user}},
        _conn
      ) do
    int_payer_id = options["sub_options"]["user"] |> String.to_integer()
    int_user_id = user["id"] |> String.to_integer()

    case Money.create_claim(
           DiscordService,
           int_user_id,
           int_payer_id,
           options["sub_options"]["unit"],
           cast_int(options["sub_options"]["amount"])
         ) do
      {:ok, {claim, _, _, _}} -> {:ok, "make", claim}
      {:error, :money_not_found} -> {:error, "make", :money_not_found}
      {:error, :invalid_amount} -> {:error, "make", :invalid_amount}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "approve"} = options,
        %{"member" => %{"user" => user}},
        _conn
      ) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"] |> String.to_integer()

    case Money.approve_claim(DiscordService, id, int_user_id) do
      {:ok, {claim, _, _, _}} -> {:ok, "approve", claim}
      {:error, err} -> {:error, "approve", err}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "deny"} = options,
        %{"member" => %{"user" => user}},
        _conn
      ) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"] |> String.to_integer()

    case Money.deny_claim(DiscordService, id, int_user_id) do
      {:ok, {claim, _, _, _}} -> {:ok, "deny", claim}
      {:error, err} -> {:error, "deny", err}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "cancel"} = options,
        %{"member" => %{"user" => user}},
        _conn
      ) do
    id = options["sub_options"]["id"]
    int_user_id = user["id"] |> String.to_integer()

    case Money.cancel_claim(DiscordService, id, int_user_id) do
      {:ok, {claim, _, _, _}} -> {:ok, "cancel", claim}
      {:error, err} -> {:error, "cancel", err}
    end
  end
end
