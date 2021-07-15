defmodule VirtualCryptoWeb.Interaction.Claim.List.Component do
  def page(user, options) do
    {a, b, options} =
      VirtualCryptoWeb.Interaction.Claim.List.page(
        user,
        options,
        []
      )

    {"claim", {a, b, options |> Map.put(:type, :button)}}
  end
end
