defmodule VirtualCryptoWeb.Interaction.Claim.List do
  alias VirtualCrypto.Money
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCryptoWeb.Interaction.Claim.List.Options
  use Bitwise

  defp extract_statuses(m) do
    m = Map.take(m, [:pending, :approved, :denied, :canceled])

    case m |> Enum.filter(fn {_k, v} -> v end) |> Enum.map(fn {k, _v} -> k end) do
      [] -> ["pending"]
      x -> x |> Enum.map(&to_string/1)
    end
  end

  def page(user, %Options{} = options, selected_claim_ids) do
    int_user_id = String.to_integer(user["id"])
    statuses = extract_statuses(options)

    claims =
      Money.get_claims(
        %DiscordUser{id: int_user_id},
        statuses,
        options.position,
        options.related_user,
        :desc_claim_id,
        %{page: options.page},
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

    {:ok, options.position,
     claims
     |> Map.put(:me, int_user_id)
     |> Map.put(:options, options)}
  end
end
