defmodule VirtualCryptoWeb.Api.V1V2.CurrenciesViewCommon do
  def error(%{error: error, error_description: error_description}) do
    %{
      error: to_string(error),
      error_description: to_string(error_description)
    }
  end

  def error(%{error: error}) do
    %{
      error: to_string(error)
    }
  end

  def ok(%{
        params: %{
          amount: amount,
          name: name,
          unit: unit,
          guild: guild,
          pool_amount: pool
        }
      }) do
    %{
      total_amount: to_string(amount),
      name: name,
      unit: unit,
      guild: to_string(guild),
      pool_amount: to_string(pool)
    }
  end
end
