defmodule VirtualCryptoWeb.Interaction.Button do
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  alias VirtualCryptoWeb.Interaction.Claim.Helper
  alias VirtualCryptoWeb.Interaction.Claim.Component
  alias VirtualCryptoWeb.Interaction.Claim.List.Options

  defp handle_listing(user, %Options{} = options) do
    Component.page(user, options)
  end

  defp action_str(:approve), do: "支払いました。"
  defp action_str(:deny), do: "拒否しました。"
  defp action_str(:cancel), do: "キャンセルしました。"

  defp handle_patch(
         subcommand,
         binary,
         user
       ) do
    new_status =
      case subcommand do
        :approve -> "approved"
        :deny -> "denied"
        :cancel -> "canceled"
      end

    {options, <<num::integer, rest::binary>>} = Options.parse(binary)
    size = num * 8
    <<claim_ids::binary-size(size), _rest::binary>> = rest

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
    {Component.page(user, options), webhook_body}
  end

  def handle(
        [:claim, :list, subcommand],
        binary,
        %{
          "member" => %{"user" => user}
        },
        _conn
      )
      when subcommand in [:sent, :received, :all] do
    {options, <<>>} = Options.parse(binary)
    handle_listing(user, options)
  end

  def handle(
        [:claim, :action, :back],
        binary,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    {options, <<num::integer, rest::binary>>} = Options.parse(binary)

    size = num * 8
    <<_claim_ids::binary-size(size), _rest::binary>> = rest


    Component.page(user, options)
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
