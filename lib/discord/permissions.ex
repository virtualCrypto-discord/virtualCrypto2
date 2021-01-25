defmodule Discord.Permissions do
  @moduledoc false
  use Bitwise

  @spec check(integer, integer) :: bool
  def check(permissions, permission) do
    (permissions &&& permission) == permission
  end

  def administrator(), do: 0x8
end
