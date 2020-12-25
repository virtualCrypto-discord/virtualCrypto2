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

  def verify( conn ) do
    public_key = Application.get_env(:virtualCrypto, :public_key) |> Base.decode16!(case: :lower)
    signature = conn.req_headers |> get_signature |> Base.decode16!(case: :lower)
    timestamp = get_timestamp conn.req_headers
    body = hd conn.assigns.raw_body
    message = timestamp <> body

    :public_key.verify(
      message,
      :none,
      signature,
      {:ed_pub, :ed25519 , public_key}
    )
  end

  def verified( conn, %{ "type" => type } = params ) do
    case type do
      1 -> render( conn, "pong.json", params: params )
      2 -> render( conn, "interactions.json", params: params )
      _ -> conn
           |> put_resp_content_type("text/plain")
           |> send_resp(404, 'Type Not Found')
    end
  end

  def index( conn, params ) do
    if verify(conn),
      do: verified(conn, params),
      else: conn
            |> put_resp_content_type("text/plain")
            |> send_resp(401, 'invalid request signature')
  end
end