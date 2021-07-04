defmodule VirtualCryptoWeb.IdempotencyLayer.Plug do
  import Plug.Conn

  def init([behavior: _behavior] = options) do
    options
  end

  @spec call(conn :: Plug.Conn.t(), m :: [behavior: VirtualCryptoWeb.IdempotencyLayer]) ::
          Plug.Conn.t()
  def call(conn, kw) do
    behavior = Keyword.fetch!(kw, :behavior)
    idempotency_keys = get_req_header(conn, "idempotency-key")

    with {:idempotency_key, 1} <- {:idempotency_key, length(idempotency_keys)},
         idempotency_key <- hd(idempotency_keys) do
      %Plug.Conn{} = behavior.interrupt(conn, idempotency_key)
    else
      {:idempotency_key, 0} ->
        conn

      {:idempotency_key, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{
            error: "invalid_request",
            error_description: "multiple_idempotency_key_header_is_not_supported"
          })
        )
        |> halt()
    end
  end
end
