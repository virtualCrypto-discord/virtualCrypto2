defmodule VirtualCryptoWeb.Interaction.Modal do
  def handle(
        [:delete, :confirm],
        _binary,
        %{
          "guild_id" => guild_id,
          "data" => %{"components" => [%{"components" => [%{"value" => v}]}]}
        },
        _conn
      ) do
    int_guild_id = String.to_integer(guild_id)
    now = Process.get(:test_delete_now) || NaiveDateTime.utc_now()

    result =
      case VirtualCrypto.Money.delete(int_guild_id, dry_run: true, now: now) do
        {:ok, :deleted, currency} ->
          required_text = "delete #{currency.unit}"

          if required_text == v do
            case VirtualCrypto.Money.delete(int_guild_id,
                   dry_run: false,
                   now: now
                 ) do
              {:ok, :deleted, currency} -> {:ok, :deleted, currency}
              {:ok, :not_exist, currency} -> {:error, :not_exist, currency}
              {:error, :out_of_term, currency} -> {:error, :out_of_term, currency}
            end
          else
            {:error, :confirmation_failed, currency}
          end

        {:ok, :not_exist, currency} ->
          {:error, :not_exist, currency}

        {:error, :out_of_term, currency} ->
          {:error, :out_of_term, currency}
      end

    {"delete", result}
  end
end
