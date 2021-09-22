defmodule InteractionsControllerTest.Pay.Helper do
  import InteractionsControllerTest.Helper.Common

  defp pay_data(%{receiver: receiver, amount: amount, unit: unit}) do
    %{
      name: "pay",
      options: [
        %{
          name: "user",
          value: to_string(receiver)
        },
        %{
          name: "amount",
          value: amount
        },
        %{
          name: "unit",
          value: unit
        }
      ]
    }
  end

  def from_guild(m, sender) do
    execute_from_guild(m |> pay_data, sender)
  end

  def valid_idempotency_status?(conn, status) do
    Plug.Conn.get_resp_header(conn, "idempotency-status") == [status]
  end

  def idempotency_not_requested?(conn) do
    valid_idempotency_status?(conn, "Not Requested")
  end

  def idempotency_ok?(conn) do
    valid_idempotency_status?(conn, "OK")
  end

  def idempotency_duplicate?(conn) do
    valid_idempotency_status?(conn, "Duplicate")
  end
end
