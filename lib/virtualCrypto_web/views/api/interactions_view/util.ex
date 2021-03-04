defmodule VirtualCryptoWeb.Api.InteractionsView.Util do
  def mention(id) do
    ~s/<@#{id}>/
  end
end
