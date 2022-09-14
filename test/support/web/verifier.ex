defmodule VirtualCryptoWeb.TestDataVerifier do
  defmacro __using__(_opts) do
    import String, only: [to_integer: 1]

    quote do
      def verify_claim(claim, m) do
        %{
          amount: amount,
          claimant: claimant,
          payer: payer,
          currency: currency,
          status: status
        } = m

        assert to_integer(claim["amount"]) == amount
        assert claim["status"] == status
        verify_user(claim["claimant"], claimant)
        verify_user(claim["payer"], payer)
        verify_currency(claim["currency"], currency)
        verify_metadata(claim["metadata"], Map.get(m, :metadata, %{}))
      end

      def verify_user(user, user_) do
        if Map.get(user_, :id) != nil do
          assert user["id"] == user_.id
        else
          assert(is_binary(user["id"]))
        end

        if Map.get(user_, :discord) != nil do
          assert to_integer(user["discord"]["id"]) == user_.discord.id
        end
      end

      def verify_currency(currency, currency_) do
        assert currency["unit"] == currency_.unit
        assert currency["name"] == currency_.name

        case Map.fetch(currency_, :total_amount) do
          {:ok, total_amount} ->
            assert currency["total_amount"] == total_amount

          :error ->
            nil
        end
      end

      def verify_metadata(a, b) do
        assert a == b
      end
    end
  end
end
