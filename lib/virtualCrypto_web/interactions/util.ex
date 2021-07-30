defmodule VirtualCryptoWeb.Interaction.Util do
  def get_user(%{
        "member" => %{"user" => user}
      }) do
    user
  end

  def get_user(%{"user" => user}) do
    user
  end
end
