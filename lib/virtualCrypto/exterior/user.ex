defmodule VirtualCrypto.Exterior.User do
  alias VirtualCrypto.User, as: U

  defprotocol Resolvable do
    @type t :: term()
    def resolve(exterior)
    def resolve_id(exterior)
    def resolver(exterior)
    def is?(exterior, user)
  end

  defmodule Resolver do
    use VirtualCrypto.Exterior.Resolver, resolvable: Resolvable
  end

  defmodule Discord do
    @type t :: %Discord{id: non_neg_integer()}

    defstruct [:id]

    def resolves(discords) do
      discord_ids = discords |> Enum.map(& &1.id)
      {:ok, users} = U.insert_users_if_not_exists(discord_ids)

      users =
        users
        |> Map.new(fn user -> {user.discord_id, user} end)

      discord_ids |> Enum.map(fn discord_id -> Map.get(users, discord_id) end)
    end

    def resolve_ids(discords) do
      resolves(discords) |> Enum.map(& &1.id)
    end
  end

  defmodule VirtualCrypto do
    @type t :: %VirtualCrypto{id: non_neg_integer()}
    defstruct [:id]

    def resolves(vcs) do
      users = U.get_users_by_id(resolve_ids(vcs)) |> Map.new(fn user -> {user.id, user} end)
      vcs |> Enum.map(fn vc -> Map.get(users, vc) end)
    end

    def resolve_ids(vcs) do
      vcs |> Enum.map(& &1.id)
    end
  end

  defimpl Resolvable, for: Discord do
    def resolve(exterior) do
      {:ok, u} = U.insert_user_if_not_exists(exterior.id)
      u
    end

    def resolve_id(exterior) do
      resolve(exterior).id
    end

    def resolver(_exterior) do
      Discord
    end

    def is?(exterior, user) do
      exterior.id == user.discord_id
    end
  end

  defimpl Resolvable, for: VirtualCrypto do
    def resolve(exterior) do
      U.get_user_by_id(exterior.id)
    end

    def resolve_id(exterior) do
      exterior.id
    end

    def resolver(_exterior) do
      VirtualCrypto
    end

    def is?(exterior, user) do
      exterior.id == user.id
    end
  end

  defmodule VirtualCryptoInstanceResolver do
    def resolves(instances) do
      instances
    end

    def resolve_ids(instances) do
      instances |> Enum.map(& &1.id)
    end
  end

  defimpl Resolvable, for: U.User do
    def resolve(user) do
      user
    end

    def resolve_id(user) do
      user.id
    end

    def resolver(_exterior) do
      VirtualCryptoInstanceResolver
    end

    def is?(exterior, user) do
      exterior.id == user.id
    end
  end
end
