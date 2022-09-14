defmodule VirtualCryptoWeb.Api.V1V2.CurrenciesViewCommon do
  use VirtualCryptoWeb, :view

  def render("error.json", %{error: error, error_description: error_description}) do
    %{
      error: to_string(error),
      error_description: to_string(error_description)
    }
  end

  def render("error.json", %{error: error}) do
    %{
      error: to_string(error)
    }
  end

  def render("ok.json", %{
        params: %{
          amount: amount,
          name: name,
          unit: unit
        }
      }) do
    %{
      total_amount: to_string(amount),
      name: name,
      unit: unit
    }
  end
end
