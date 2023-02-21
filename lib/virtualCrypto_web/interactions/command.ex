defmodule VirtualCryptoWeb.Interaction.Command do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCryptoWeb.Interaction.Claim.List.Options
  import VirtualCryptoWeb.Interaction.Util, only: [get_user: 1]

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

  defp continue_management_command?(guild, int_permissions) do
    if "APPLICATION_COMMAND_PERMISSIONS_V2" in guild["features"] do
      Discord.Permissions.check(int_permissions, Discord.Permissions.administrator())
    else
      true
    end
  end

  def handle(
        "bal",
        _options,
        payload,
        _conn
      ) do
    %{"id" => executor} = get_user(payload)
    int_executor = String.to_integer(executor)
    Money.balance(user: %DiscordUser{id: int_executor})
  end

  def handle(
        "pay",
        %{"unit" => unit, "user" => receiver, "amount" => amount},
        payload,
        _conn
      ) do
    %{"id" => sender} = get_user(payload)
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
        conn
      ) do
    int_permissions = String.to_integer(perms)
    int_guild = String.to_integer(guild)

    guild =
      Discord.Api.Cached.get_guild(
        int_guild,
        VirtualCryptoWeb.Plug.DiscordApiService.get_service(conn)
      )

    if continue_management_command?(guild, int_permissions) do
      int_receiver = %DiscordUser{id: String.to_integer(receiver)}
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
        %{
          "guild_id" => _
        } = payload,
        conn
      ) do
    handle("give", Map.merge(%{"amount" => :all}, m), payload, conn)
  end

  def handle(
        "give",
        _,
        _payload,
        _conn
      ) do
    {:error, :run_in_dm}
  end

  def handle(
        "create",
        options,
        %{"guild_id" => guild_id, "member" => %{"user" => user}} = params,
        conn
      ) do
    int_guild_id = String.to_integer(guild_id)
    int_user_id = String.to_integer(user["id"])
    int_permissions = String.to_integer(params["member"]["permissions"])
    options = %{options | "amount" => cast_int(options["amount"])}

    guild =
      Discord.Api.Cached.get_guild(
        int_guild_id,
        VirtualCryptoWeb.Plug.DiscordApiService.get_service(conn)
      )

    if continue_management_command?(guild, int_permissions) do
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

  def handle(
        "create",
        _options,
        _,
        _conn
      ) do
    {:error, :run_in_dm, %{}}
  end

  def handle("info", options, payload, conn) do
    user = get_user(payload)
    int_user_id = String.to_integer(user["id"])

    guild_query =
      case payload do
        %{"guild_id" => guild_id} -> [guild: guild_id]
        _ -> []
      end

    name = options["name"]
    unit = options["unit"]

    case {name, unit, guild_query} do
      {nil, nil, []} ->
        {:error, :must_supply_argument_when_run_in_dm}

      _ ->
        query = [name: name, unit: unit] ++ guild_query

        case VirtualCrypto.Money.info(query) do
          nil ->
            {:error, :not_found}

          info ->
            guild =
              Discord.Api.Cached.get_guild(
                info.guild,
                VirtualCryptoWeb.Plug.DiscordApiService.get_service(conn)
              )

            case Money.balance(user: %DiscordUser{id: int_user_id})
                 # FIXME: do not client side filtering
                 |> Enum.filter(fn x -> x.currency.unit == info.unit end) do
              [balance] -> {:ok, %{info: info, amount: balance.asset.amount, guild: guild}}
              [] -> {:ok, %{info: info, amount: 0, guild: guild}}
            end
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
        payload,
        _conn
      )
      when subcommand in ["list", "received", "sent"] do
    user = get_user(payload)

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
        payload,
        _conn
      ) do
    int_payer_id = options["sub_options"]["user"] |> String.to_integer()
    user = get_user(payload)
    int_user_id = user["id"] |> String.to_integer()

    case Money.create_claim(
           %DiscordUser{id: int_user_id},
           %DiscordUser{id: int_payer_id},
           options["sub_options"]["unit"],
           cast_int(options["sub_options"]["amount"]),
           nil
         ) do
      {:ok, %{claim: claim}} -> {:ok, "make", claim}
      {:error, :not_found_currency} -> {:error, "make", :not_found_currency}
      {:error, :invalid_amount} -> {:error, "make", :invalid_amount}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "approve"} = options,
        payload,
        _conn
      ) do
    id = options["sub_options"]["id"]
    user = get_user(payload)
    int_user_id = user["id"] |> String.to_integer()

    case Money.approve_claim(id, %DiscordUser{id: int_user_id}, %{}) do
      {:ok, %{claim: claim}} -> {:ok, "approve", claim}
      {:error, err} -> {:error, "approve", err}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "deny"} = options,
        payload,
        _conn
      ) do
    id = options["sub_options"]["id"]
    user = get_user(payload)
    int_user_id = user["id"] |> String.to_integer()

    case Money.deny_claim(id, %DiscordUser{id: int_user_id}, %{}) do
      {:ok, %{claim: claim}} -> {:ok, "deny", claim}
      {:error, err} -> {:error, "deny", err}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "cancel"} = options,
        payload,
        _conn
      ) do
    id = options["sub_options"]["id"]
    user = get_user(payload)
    int_user_id = user["id"] |> String.to_integer()

    case Money.cancel_claim(id, %DiscordUser{id: int_user_id}, %{}) do
      {:ok, %{claim: claim}} -> {:ok, "cancel", claim}
      {:error, err} -> {:error, "cancel", err}
    end
  end

  def handle(
        "claim",
        %{"subcommand" => "show"} = options,
        payload,
        _conn
      ) do
    id = options["sub_options"]["id"]
    user = get_user(payload)
    int_user_id = user["id"] |> String.to_integer()
    user = %DiscordUser{id: int_user_id}

    case Money.get_claim_by_id(user, id) do
      {:error, err} ->
        {:error, "show", err}

      %{payer: payer, claimant: claimant} = claim
      when int_user_id in [payer.discord_id, claimant.discord_id] ->
        data =
          claim
          |> Map.merge(%{
            me: int_user_id,
            action: :command
          })

        data =
          case data do
            %{claim: %{status: "pending"}, payer: %{discord_id: ^int_user_id}} ->
              assets = VirtualCrypto.Money.balance(user: user)
              data |> Map.put(:assets, assets)

            _ ->
              data
          end

        {:ok, "show", data}

      %{} ->
        {:error, "show", :not_found}
    end
  end
end
