defmodule VirtualCryptoWeb.Interaction.Claim.Component do
  def page(subcommand, query, user) do
    page =
      case Map.fetch!(query, "page") |> String.to_integer() do
        -1 -> :last
        x -> x
      end

    {a, b, params} =
      VirtualCryptoWeb.Interaction.Claim.List.page(
        user,
        subcommand,
        page,
        %{}
        |> Map.merge(
          query
          |> Map.get("flags", "0")
          |> VirtualCryptoWeb.Interaction.Claim.List.decode_options()
        )
        |> Map.put(
          :related_user_id,
          case query["user"] do
            nil -> nil
            uid -> String.to_integer(uid)
          end
        ),
        []
      )

    {"claim", {a, b, params |> Map.put(:type, :button)}}
  end
end
