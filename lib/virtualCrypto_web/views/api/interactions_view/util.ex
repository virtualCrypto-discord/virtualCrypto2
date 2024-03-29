defmodule VirtualCryptoWeb.Api.InteractionsView.Util do
  def pong, do: 1
  def channel_message_with_source, do: 4
  def update_message, do: 7
  def modal, do: 9
  def ephemeral, do: 64
  def color_ok, do: 0x38EA42
  def color_error, do: 0xEA3875
  def color_brand, do: 0x6221ED
  @spec mention(String.t() | non_neg_integer()) :: String.t()
  def mention(id) do
    ~s/<@#{id}>/
  end

  @spec format_date_time(NaiveDateTime.t()) :: String.t()
  def format_date_time(naive_date_time) do
    timestamp = naive_date_time |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
    # https://discord.com/developers/docs/reference#message-formatting-formats
    "<t:#{timestamp}>"
  end

  def action_row(), do: 1
  def button(), do: 2
  def select_menu(), do: 3
  def text_input(), do: 4
  def button_style_primary(), do: 1
  def button_style_secondary(), do: 2
  def button_style_success(), do: 3
  def button_style_danger(), do: 4
  def button_style_link(), do: 5
  def text_input_style_short(), do: 1
  def text_input_style_paragraph(), do: 2
end
