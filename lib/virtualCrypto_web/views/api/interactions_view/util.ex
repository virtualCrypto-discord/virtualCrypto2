defmodule VirtualCryptoWeb.Api.InteractionsView.Util do
  @spec mention(String.t() | non_neg_integer()) :: String.t()
  def mention(id) do
    ~s/<@#{id}>/
  end

  @spec format_date_time(NaiveDateTime.t()) :: String.t()
  def format_date_time(naive_date_time) do
    d =
      naive_date_time
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.shift_zone!("Asia/Tokyo", Tzdata.TimeZoneDatabase)

    ~s/#{d.year}\/#{d.month}\/#{d.day} #{d.hour}:#{d.minute}(#{d.zone_abbr})/
  end
end
