defmodule VirtualCryptoWeb.Interaction.Button do
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCryptoWeb.Interaction.Claim.Helper
  alias VirtualCryptoWeb.Interaction.Claim.Component

  defp handle_listing(subcommand, data, user) do
    query = data |> Helper.drop_tail_0() |> URI.decode_query()
    Component.page(subcommand, query, user)
  end

  defp action_str(:approve), do: "支払いました。"
  defp action_str(:deny), do: "拒否しました。"
  defp action_str(:cancel), do: "キャンセルしました。"

  defp handle_patch(
         subcommand,
         <<num::integer, rest::binary>>,
         user
       ) do
    new_status =
      case subcommand do
        :approve -> "approved"
        :deny -> "denied"
        :cancel -> "canceled"
      end

    size = num * 8
    <<claim_ids::binary-size(size), rest::binary>> = rest

    query = rest |> Helper.drop_tail_0() |> URI.decode_query()

    claim_ids = Helper.destructuring_claim_ids(claim_ids)

    webhook_body =
      case VirtualCrypto.Money.update_claims(
             claim_ids
             |> Enum.map(fn id ->
               %{
                 id: id,
                 status: new_status
               }
             end),
             %DiscordUser{id: String.to_integer(user["id"])}
           ) do
        {:ok, claims} ->
          claim_id_str = claims |> Enum.map(& &1.id) |> Enum.map(&"`#{&1}`") |> Enum.join(",")

          %{
            content: "請求id #{claim_id_str} の請求を" <> action_str(subcommand)
          }

        {:error, :invalid_current_status} ->
          %{
            content: "処理しようとした請求はすでに処理済みです。"
          }
      end

    webhook_body = webhook_body |> Map.put(:flags, 64)
    {Component.page(String.to_atom(Map.fetch!(query, "sc")), query, user), webhook_body}
  end

  def handle(
        [:claim, :list, subcommand],
        data,
        %{
          "member" => %{"user" => user}
        },
        _conn
      )
      when subcommand in [:sent, :received, :all] do
    handle_listing(subcommand, data, user)
  end

  def handle(
        [:claim, :action, :back],
        <<num::integer, rest::binary>>,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    size = num * 8
    <<_claim_ids::binary-size(size), rest::binary>> = rest

    query = rest |> Helper.drop_tail_0() |> URI.decode_query()

    Component.page(String.to_atom(Map.fetch!(query, "sc")), query, user)
  end

  def handle(
        [:claim, :action, subcommand],
        data,
        %{
          "member" => %{"user" => user}
        },
        _conn
      )
      when subcommand in [:approve, :deny, :cancel] do
    handle_patch(subcommand, data, user)
  end
end
