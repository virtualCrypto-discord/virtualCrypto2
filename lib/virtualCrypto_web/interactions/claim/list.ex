defmodule VirtualCryptoWeb.Interaction.Claim.List do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  use Bitwise

  defp statuses(nil) do
    statuses(%{})
  end

  defp statuses(m) do
    m = Map.take(m, ["pending", "approved", "denied", "canceled"])
    values = Map.values(m)

    if values |> Enum.any?(&(&1 != nil)) do
      m
      |> Enum.filter(fn
        {_k, v} when is_boolean(v) -> v
        {_k, v} when is_binary(v) -> v == "1"
      end)
      |> Enum.map(fn {k, _v} -> k end)
    else
      ["pending"]
    end
  end

  defp options_flags() do
    %{
      "pending" => 0x01,
      "approved" => 0x02,
      "denied" => 0x04,
      "canceled" => 0x08,
      "received" => 0x10,
      "sent" => 0x20
    }
  end

  def encode_options(options) do
    m = options_flags()

    options |> Enum.reduce(0, fn e, acc -> acc ||| Map.get(m, e, 0) end)
  end

  def decode_options(flags) do
    flags = flags |> String.to_integer()
    m = options_flags()

    m
    |> Enum.filter(fn {_k, v} -> (flags &&& v) != 0 end)
    |> Enum.map(fn {k, _} -> {k, true} end)
    |> Map.new()
  end

  def page(user, subcommand, page, nil, selected_claim_ids) do
    page(user, subcommand, page, %{}, selected_claim_ids)
  end

  def page(user, subcommand, page, options, selected_claim_ids) do
    sr_filter =
      case subcommand do
        :all -> :all
        :received -> :received
        :sent -> :claimed
      end

    int_user_id = String.to_integer(user["id"])
    statuses = statuses(options)
    related_user_id = Map.get(options, :related_user_id)

    query = %{flags: encode_options(statuses)}

    query =
      case related_user_id do
        nil -> query
        _ -> query |> Map.put(:user, related_user_id)
      end

    claims =
      Money.get_claims(
        %DiscordUser{id: int_user_id},
        statuses,
        sr_filter,
        related_user_id,
        :desc_claim_id,
        %{page: page},
        5
      )

    claims = %{
      claims
      | claims:
          claims.claims
          |> Enum.map(fn %{claim: %{id: id}} = m ->
            m |> Map.put(:selected, id in selected_claim_ids)
          end)
    }

    {:ok, subcommand,
     claims
     |> Map.put(:me, int_user_id)
     |> Map.put(:query, query)}
  end
end
