defmodule VirtualCryptoWeb.Api.V1V2.ClaimViewCommon do
  use VirtualCryptoWeb, :view

  def render("error.json", %{
        error: error,
        error_info: error_info,
        error_description: error_description
      }) do
    %{
      error: error,
      error_description: error_description,
      error_info: error_info
    }
  end

  def render("error.json", %{
        error: error,
        error_description: error_description,
        error_description_details: details
      }) do
    %{
      error: error,
      error_description: error_description,
      error_description_details: details
    }
  end

  def render("error.json", %{error: error, error_description: error_description}) do
    %{
      error: error,
      error_description: error_description
    }
  end

  def render("error.json", %{error: error, error_info: error_info}) do
    %{
      error: error,
      error_info: error_info
    }
  end

  def render("data.json", %{params: data}) do
    data
  end
end
