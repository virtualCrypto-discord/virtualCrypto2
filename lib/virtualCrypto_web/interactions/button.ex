defmodule VirtualCryptoWeb.Interaction.Button do
  def handle(
        ["claim", "list", "last"],
        _query,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    {a, b, params} = VirtualCryptoWeb.Interaction.Claim.List.last(user)

    {"claim", {a, b, params |> Map.put(:type, :button)}}
  end

  def handle(
        ["claim", "list", n],
        _query,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    {a, b, params} = VirtualCryptoWeb.Interaction.Claim.List.page(user, n |> String.to_integer())

    {"claim", {a, b, params |> Map.put(:type, :button)}}
  end
end
