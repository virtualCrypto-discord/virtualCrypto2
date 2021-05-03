defmodule VirtualCryptoWeb.Api.InteractionsView.Util do
  def channel_message_with_source, do: 4
  def pong, do: 1
  def ephemeral,do: 64
  @spec mention(String.t() | non_neg_integer()) :: String.t()
  def mention(id) do
    ~s/<@#{id}>/
  end

  defp padding(d) do
    d |> Integer.to_string() |> String.pad_leading(2, "0")
  end

  @spec format_date_time(NaiveDateTime.t()) :: String.t()
  def format_date_time(naive_date_time) do
    d =
      naive_date_time
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.shift_zone!("Asia/Tokyo", Tzdata.TimeZoneDatabase)

    ~s/#{d.year}\/#{d.month |> padding}\/#{d.day |> padding} #{d.hour |> padding}:#{
      d.minute |> padding
    }(#{d.zone_abbr})/
  end
end
