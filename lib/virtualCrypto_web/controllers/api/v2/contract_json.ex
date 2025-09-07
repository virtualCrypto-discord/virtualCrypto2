defmodule VirtualCryptoWeb.Api.V2.ContractJSON do
  def error(%{error: error, error_description: error_description}) do
    %{
      error: error,
      error_description: error_description
    }
  end

  def error(%{error: error}) do
    %{
      error: error
    }
  end

  def data(%{contract: contract}) do
    contract
  end
end
