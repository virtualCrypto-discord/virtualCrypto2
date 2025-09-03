defmodule VirtualCryptoWeb.Api.V1.InfoJSON do
  def ok(data), do: VirtualCryptoWeb.Api.V1V2.CurrenciesViewCommon.ok(data)
  def error(data), do: VirtualCryptoWeb.Api.V1V2.CurrenciesViewCommon.error(data)
end
