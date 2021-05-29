defmodule VirtualCryptoWeb.Interaction.Button do
  defp handle_(page, query, user) do
    query = query|> Map.new()
    {a, b, params} =
      VirtualCryptoWeb.Interaction.Claim.List.page(
        user,
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
        )
      )

    {"claim", {a, b, params |> Map.put(:type, :button)}}
  end

  def handle(
        ["claim", "list", "last"],
        query,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    handle_(:last, query, user)
  end

  def handle(
        ["claim", "list", n],
        query,
        %{
          "member" => %{"user" => user}
        },
        _conn
      ) do
    handle_(n |> String.to_integer(), query, user)
  end
end
