defmodule VirtualCryptoWeb.Interaction.Button do
  def handle(
        ["claim", "list", "last"],
        query,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    {a, b, params} =
      VirtualCryptoWeb.Interaction.Claim.List.last(
        user,
        query
        |> Map.new()
        |> Map.get("flags", "0")
        |> VirtualCryptoWeb.Interaction.Claim.List.decode_options()
      )

    {"claim", {a, b, params |> Map.put(:type, :button)}}
  end

  def handle(
        ["claim", "list", n],
        query,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    {a, b, params} =
      VirtualCryptoWeb.Interaction.Claim.List.page(
        user,
        n |> String.to_integer(),
        query
        |> Map.new()
        |> Map.get("flags", "0")
        |> VirtualCryptoWeb.Interaction.Claim.List.decode_options()
      )

    {"claim", {a, b, params |> Map.put(:type, :button)}}
  end
end
