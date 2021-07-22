defmodule InteractionsControllerTest.Claim.List.Options do
  use ExUnit.Case
  alias VirtualCryptoWeb.Interaction.Claim.List.Options, as: ListOptions

  test "list options" do
    boolean = [true, false]

    for pending <- boolean,
        approved <- boolean,
        denied <- boolean,
        canceled <- boolean,
        position <- [:all, :received, :claimed],
        page <- [:last,1,2,3],
        related_user <- [nil, 123_456_789_012_345_678] do
      options = %ListOptions{
        # 1bit
        pending: pending,
        # 1bit
        approved: approved,
        # 1bit
        denied: denied,
        # 1bit
        canceled: canceled,
        # 2bit
        position: position,
        # reserved 2bit
        # 32bit
        # if 0 then last
        page: page,
        # 64bit
        # if 0 then nothing filter
        related_user: related_user
      }

      assert {^options, _} = ListOptions.parse(ListOptions.encode(options))
    end
  end
end
