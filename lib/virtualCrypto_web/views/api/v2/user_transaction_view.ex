defmodule VirtualCryptoWeb.Api.V2.UserTransactionView do
  use VirtualCryptoWeb, :view

  def render("pass.json", %{_json: json}) do
    json
  end
end

defmodule VirtualCryptoWeb.Api.V2.UserTransactionView.Pure do
  defp render_error(:not_found_money) do
    %{
      error: "invalid_request",
      error_info: "not_found_money"
    }
  end

  defp render_error(:not_found_sender_asset) do
    render_error(:not_enough_amount)
  end

  defp render_error(:not_enough_amount) do
    %{
      error: "conflict",
      error_info: "not_enough_amount"
    }
  end

  defp render_error(:invalid_amount) do
    %{
      error: "invalid_request",
      error_description: "invalid_amount"
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

  def render("ok.json", %{}) do
    %{}
  end
end
