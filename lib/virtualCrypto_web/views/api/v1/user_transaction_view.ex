defmodule VirtualCryptoWeb.Api.V1.UserTransactionView do
  use VirtualCryptoWeb, :view

  defp render_error(:not_found_money) do
    %{
      error: "invalid_request",
      error_info: "not_found_money"
    }
  end

  defp render_error(:not_found_sender_asset) do
    %{
      error: "invalid_request",
      error_info: "not_found_sender_asset"
    }
  end

  defp render_error(:not_enough_amount) do
    %{
      error: "invalid_request",
      error_info: "not_enough_amount"
    }
  end

  def render("error.json", %{
        error: {error, error_description}
      }) do
    %{
      error: to_string(error),
      error_description: to_string(error_description)
    }
  end

  def render("error.json", %{
        error: error
      }) do
    render_error(error)
  end
end
