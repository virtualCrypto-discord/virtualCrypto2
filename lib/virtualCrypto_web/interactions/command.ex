defmodule VirtualCryptoWeb.Interaction.Command do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCryptoWeb.Interaction.Claim.List.Options
  @moduledoc false
  @bot_invite_url Application.get_env(:virtualCrypto, :invite_url)
  @guild_invite_url Application.get_env(:virtualCrypto, :support_guild_invite_url)
  @site_url Application.get_env(:virtualCrypto, :site_url)

  # NOTE: https://github.com/virtualCrypto-discord/virtualCrypto2/issues/167
  defp cast_int(v) when is_binary(v) do
    String.to_integer(v)
  end

  defp cast_int(v) when is_integer(v) do
    v
  end

  defp cast_int(v) do
    v
  end

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

  defp resolve_status_filter(sub_options) do
    sub_options = Map.take(sub_options, ["approved", "canceled", "denied", "pending"])

    case map_size(sub_options) do
      0 -> %{pending: true}
      _ -> sub_options |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end) |> Map.new()
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
    Money.balance(user: %DiscordUser{id: int_executor})
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
           sender: %DiscordUser{id: int_sender},
           receiver: %DiscordUser{id: int_receiver},
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
      int_receiver = %DiscordUser{id: String.to_integer(receiver)}
      int_guild = String.to_integer(guild)
      int_amount = cast_int(amount)

      case VirtualCrypto.Money.give(receiver: int_receiver, amount: int_amount, guild: int_guild) do
        {:ok,
         %{
           currency: %VirtualCrypto.Money.Currency{unit: unit, pool_amount: pool_amount},
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
               creator: %DiscordUser{id: int_user_id},
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

  def handle("info", options, %{"guild_id" => guild_id, "member" => %{"user" => user}}, conn) do
    int_user_id = String.to_integer(user["id"])

    case VirtualCrypto.Money.info(name: options["name"], unit: options["unit"], guild: guild_id) do
      nil ->
        {:error, nil, nil, nil}

      info ->
        guild = VirtualCryptoWeb.Plug.DiscordApiService.get_service(conn).get_guild(info.guild)

        case Money.balance(user: %DiscordUser{id: int_user_id})
             |> Enum.filter(fn x -> x.currency.unit == info.unit end) do
          [balance] -> {:ok, info, balance.asset.amount, guild}
          [] -> {:ok, info, 0, guild}
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
        %{"subcommand" => subcommand} = options,
        %{"member" => %{"user" => user}},
        _conn
      )
      when subcommand in ["list", "received", "sent"] do
    sub_options = Map.get(options, "sub_options", %{})

    subcommand =
      case subcommand do
        "list" -> :all
        "received" -> :received
        "sent" -> :claimed
      end

    status_filter = resolve_status_filter(sub_options)

    related_user =
      case Map.get(sub_options, "related_user") do
        nil -> nil
        x -> %DiscordUser{id: String.to_integer(x)}
      end

    options = %Options{
      approved: Map.get(status_filter, :approved, false),
      canceled: Map.get(status_filter, :canceled, false),
      denied: Map.get(status_filter, :denied, false),
      pending: Map.get(status_filter, :pending, false),
      page: 1,
      position: subcommand,
      related_user: related_user
    }

    case VirtualCryptoWeb.Interaction.Claim.List.page(user, options, []) do
      {a, b, c} -> {a, b, c |> Map.put(:type, :command)}
    end
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
           %DiscordUser{id: int_user_id},
           %DiscordUser{id: int_payer_id},
           options["sub_options"]["unit"],
           cast_int(options["sub_options"]["amount"])
         ) do
      {:ok, %{claim: claim}} -> {:ok, "make", claim}
      {:error, :not_found_currency} -> {:error, "make", :not_found_currency}
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

    case Money.approve_claim(id, %DiscordUser{id: int_user_id}) do
      {:ok, %{claim: claim}} -> {:ok, "approve", claim}
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

    case Money.deny_claim(id, %DiscordUser{id: int_user_id}) do
      {:ok, %{claim: claim}} -> {:ok, "deny", claim}
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

    case Money.cancel_claim(id, %DiscordUser{id: int_user_id}) do
      {:ok, %{claim: claim}} -> {:ok, "cancel", claim}
      {:error, err} -> {:error, "cancel", err}
    end
  end
end
