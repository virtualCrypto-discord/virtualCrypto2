defmodule VirtualCryptoWeb.OutgoingController do
  use VirtualCryptoWeb, :controller

  def bot(conn, _) do
    conn
    |> redirect(external: Application.get_env(:virtualCrypto, :invite_url))
    |> halt()
  end

  def guild(conn, _) do
    conn
    |> redirect(external: Application.get_env(:virtualCrypto, :support_guild_invite_url))
    |> halt()
  end
end
