defmodule VirtualCryptoWeb.IdempotencyLayer.Payments do
  @behaviour VirtualCryptoWeb.IdempotencyLayer
  alias VirtualCryptoWeb.IdempotencyLayer.Validator
  import Ecto.Query

  defp insert_idempotency_entry(idempotency_key, user_id) do
    VirtualCrypto.Repo.insert(
      %VirtualCrypto.Idempotency.Payments{
        idempotency_key: idempotency_key,
        user_id: user_id,
        expires:
          NaiveDateTime.utc_now()
          |> NaiveDateTime.add(7 * 60 * 60 * 24)
          |> NaiveDateTime.truncate(:second)
      },
      on_conflict: :nothing
    )
  end

  defp get_idempotency_entry_q(idempotency_key, user_id) do
    q =
      from(t in VirtualCrypto.Idempotency.Payments,
        where: t.idempotency_key == ^idempotency_key and t.user_id == ^user_id,
        select: t
      )

    VirtualCrypto.Repo.one(q)
  end

  defp get_or_insert_idempotency_entry(idempotency_key, user_id) do
    with nil <- VirtualCrypto.Repo.one(get_idempotency_entry_q(idempotency_key, user_id)),
         {:ok, schema} when schema.id == nil <- insert_idempotency_entry(idempotency_key, user_id) do
      {:exist, VirtualCrypto.Repo.one!(get_idempotency_entry_q(idempotency_key, user_id))}
    else
      entry -> {:exist, entry}
      {:ok, schema} -> {:create, schema}
    end
  end

  @impl VirtualCryptoWeb.IdempotencyLayer
  def interrupt(conn, idempotency_key) do
    with {_, true} <-
           {:validate_idempotency_key, Validator.valid_idempotency_key?(idempotency_key)},
         {:token, %{"sub" => user_id, "vc.pay" => true}} <-
           {:token, Guardian.Plug.current_resource(conn)},
         {:exist, idempotency_entry} <- get_or_insert_idempotency_entry(idempotency_key, user_id) do
      Plug.Conn.assign(conn, :idempotency, %{entry: idempotency_entry})
    else
      {:validate_idempotency_key, _} ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          400,
          Jason.encode!(%{
            error: "invalid_request",
            error_description: "invalid_idempotency_key"
          })
        )
        |> Plug.Conn.halt()

      {:token, _} ->
        conn
        |> Plug.Conn.send_resp(
          403,
          Jason.encode!(%{
            error: "insufficient_scope",
            error_description: "token_verification_failed"
          })
        )
        |> Plug.Conn.halt()

      {:create, _} ->
        nil
    end
  end

  def register_response(conn, body) do
    idempotency_entry = conn.assigns.idempotency.entry
    VirtualCrypto.Repo.update!(%{idempotency_entry | body: body, http_status: conn.status})
    conn
  end
end
