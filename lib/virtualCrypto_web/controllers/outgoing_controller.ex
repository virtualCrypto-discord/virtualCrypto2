defmodule VirtualCryptoWeb.OutgoingController do
  use VirtualCryptoWeb, :controller
  defp invite_url, do: Application.fetch_env!(:virtualCrypto, :invite_url)
  defp support_guild, do: Application.fetch_env!(:virtualCrypto, :support_guild_invite_url)

  def bot(conn, _) do
    conn
    |> redirect(external: invite_url())
    |> halt()
  end

  def guild(conn, _) do
    conn
    |> redirect(external: support_guild())
    |> halt()
  end
end
