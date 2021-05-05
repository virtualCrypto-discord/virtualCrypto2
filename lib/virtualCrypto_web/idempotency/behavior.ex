defmodule VirtualCryptoWeb.IdempotencyLayer do
  @callback interrupt(conn :: %Plug.Conn{}, idempotency_key :: binary()) :: %Plug.Conn{} | nil
end
