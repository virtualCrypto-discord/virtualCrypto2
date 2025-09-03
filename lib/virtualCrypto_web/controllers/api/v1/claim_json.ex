defmodule VirtualCryptoWeb.Api.V1.ClaimJSON do
  def error(data), do: VirtualCryptoWeb.Api.V1V2.ClaimViewCommon.error(data)
  def data(data), do: VirtualCryptoWeb.Api.V1V2.ClaimViewCommon.data(data)
end
