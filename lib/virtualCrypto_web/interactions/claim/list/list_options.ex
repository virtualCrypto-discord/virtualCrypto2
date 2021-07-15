defmodule VirtualCryptoWeb.Interaction.Claim.List.Options do
  use Bitwise
  alias VirtualCryptoWeb.Interaction.Claim.List.Options
  @typep position_t :: :all | :received | :sent
  @type t :: %Options{
          # 1bit
          pending: boolean(),
          # 1bit
          approved: boolean(),
          # 1bit
          denied: boolean(),
          # 1bit
          canceled: boolean(),
          # 2bit
          position: position_t(),
          # reserved 2bit
          # 32bit
          # if 0 then last
          page: non_neg_integer(),
          # 64bit
          # if 0 then nothing filter
          related_user: non_neg_integer()
        }
  defstruct [:pending, :approved, :denied, :canceled, :position, :related_user, :page]
  defp encode_bool(true), do: 1
  defp encode_bool(false), do: 0
  defp encode_position(:all), do: 0
  defp encode_position(:received), do: 1
  defp encode_position(:claimed), do: 2

  defp parse_status(1), do: true
  defp parse_status(0), do: false

  defp parse_position(0), do: :all
  defp parse_position(1), do: :received
  defp parse_position(2), do: :claimed

  def encode(%Options{
        pending: pending,
        approved: approved,
        denied: denied,
        canceled: canceled,
        position: position,
        page: page,
        related_user: related_user
      }) do
    related_user =
      case related_user do
        nil -> 0
        x -> x
      end

    page =
      case page do
        :last -> 0
        x -> x
      end

    <<encode_bool(pending)::1, encode_bool(approved)::1, encode_bool(denied)::1,
      encode_bool(canceled)::1, encode_position(position)::2, 0::2, page::32, related_user::64>>
  end

  def parse(
        <<pending::1, approved::1, denied::1, canceled::1, position::2, 0::2, page::32,
          related_user::64, rest::binary>>
      ) do
    r = %Options{
      pending: parse_status(pending),
      approved: parse_status(approved),
      denied: parse_status(denied),
      canceled: parse_status(canceled),
      position: parse_position(position),
      page:
        case page do
          0 -> :last
          x -> x
        end,
      related_user:
        case related_user do
          0 -> nil
          x -> x
        end
    }

    {r, rest}
  end

  def length(), do: 13
end
