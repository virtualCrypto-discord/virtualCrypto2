defmodule VirtualCryptoWeb.InteractionsController do
  use VirtualCryptoWeb, :controller

  defp get_signature [] do
    nil
  end

  defp get_signature [{"x-signature-ed25519", value} | tail] do
    value
  end

  defp get_signature [_ | tail] do
    get_signature tail
  end

  defp get_timestamp [] do
    nil
  end

  defp get_timestamp [{"x-signature-timestamp", value} | tail] do
    value
  end

  defp get_timestamp [_ | tail] do
    get_timestamp tail
  end

  def index( conn, params ) do

    public_key = Application.get_env(:virtualCrypto, :public_key)
    signature = get_signature conn.req_headers
    timestamp = get_timestamp conn.req_headers
    body = conn.private.raw_body
    result = Kcl.valid_signature?(
      Base.decode16!(signature),
      timestamp <> body,
      Base.decode16!(public_key  |> String.upcase))
    IO.inspect result
    IO.inspect signature
    IO.inspect timestamp
    IO.inspect body
    if result do
      render( conn, "interactions.json", params: params )
    else
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(401, 'invalid request signature')
    end
  end
end
