defmodule VirtualCryptoWeb.Api.InteractionsView.Util do
  def mention(id) do
    "<@" <> id <> ">"
  end
end
