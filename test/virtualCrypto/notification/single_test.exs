defmodule VirtualCrypto.Test.Single do
  use VirtualCrypto.DataCase, async: true
  import VirtualCrypto.EnvironmentBootstrapper, only: [setup_money: 1]
  import VirtualCryptoTest.Notification.Setup
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser

  setup :setup_money

  test "approve single claim", %{unit: unit, user1: user1, user2: user2} do
    {:ok, claim} =
      setup_claim(%{unit: unit, amount: 100, metadata: nil, receiver: user1, payer: user2})

    VirtualCrypto.Money.approve_claim(claim.claim.id, %DiscordUser{id: user2}, %{"a" => "b"})
    assert_received {:notification_sink, exterior, events}
    user = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)
    assert user.discord_id == user1
    assert [event] = events
    %{payer: payer, currency: currency} = claim

    assert %{
             amount: "100",
             currency: %{
               id: currency.id,
               name: currency.name,
               unit: currency.unit,
             },
             id: claim.claim.id,
             metadata: %{},
             payer: %{
               discord: %{id: to_string(payer.discord_id)},
               id: payer.id
             },
             status: :approved,
             updated_at: event.updated_at
           } == event

    assert %DateTime{} = event.updated_at
    assert "Etc/UTC" == event.updated_at.time_zone
  end

  test "deny single claim", %{unit: unit, user1: user1, user2: user2} do
    {:ok, claim} =
      setup_claim(%{unit: unit, amount: 100, metadata: nil, receiver: user1, payer: user2})

    VirtualCrypto.Money.deny_claim(claim.claim.id, %DiscordUser{id: user2}, %{"a" => "b"})
    assert_received {:notification_sink, exterior, events}
    user = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)
    assert user.discord_id == user1
    assert [event] = events
    %{payer: payer, currency: currency} = claim

    assert %{
             amount: "100",
             currency: %{
               id: currency.id,
               name: currency.name,
               unit: currency.unit,
             },
             id: claim.claim.id,
             metadata: %{},
             payer: %{
               discord: %{id: to_string(payer.discord_id)},
               id: payer.id
             },
             status: :denied,
             updated_at: event.updated_at
           } == event

    assert %DateTime{} = event.updated_at
    assert "Etc/UTC" == event.updated_at.time_zone
  end

  test "approve single claim with metadata", %{unit: unit, user1: user1, user2: user2} do
    {:ok, claim} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    VirtualCrypto.Money.approve_claim(claim.claim.id, %DiscordUser{id: user2}, %{"a" => "b"})
    assert_received {:notification_sink, exterior, events}
    user = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)
    assert user.discord_id == user1
    assert [event] = events
    %{payer: payer, currency: currency} = claim

    assert %{
             amount: "100",
             currency: %{
               id: currency.id,
               name: currency.name,
               unit: currency.unit,
             },
             id: claim.claim.id,
             metadata: %{"x" => "y"},
             payer: %{
               discord: %{id: to_string(payer.discord_id)},
               id: payer.id
             },
             status: :approved,
             updated_at: event.updated_at
           } == event

    assert %DateTime{} = event.updated_at
    assert "Etc/UTC" == event.updated_at.time_zone
  end

  test "deny single claim with metadata", %{unit: unit, user1: user1, user2: user2} do
    {:ok, claim} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    VirtualCrypto.Money.deny_claim(claim.claim.id, %DiscordUser{id: user2}, %{"a" => "b"})
    assert_received {:notification_sink, exterior, events}
    user = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)
    assert user.discord_id == user1
    assert [event] = events
    %{payer: payer, currency: currency} = claim

    assert %{
             amount: "100",
             currency: %{
               id: currency.id,
               name: currency.name,
               unit: currency.unit,
             },
             id: claim.claim.id,
             metadata: %{"x" => "y"},
             payer: %{
               discord: %{id: to_string(payer.discord_id)},
               id: payer.id
             },
             status: :denied,
             updated_at: event.updated_at
           } == event

    assert %DateTime{} = event.updated_at
    assert "Etc/UTC" == event.updated_at.time_zone
  end

  test "must not send notification when claim canceled", %{unit: unit, user1: user1, user2: user2} do
    {:ok, claim} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    {:ok, _} = VirtualCrypto.Money.cancel_claim(claim.claim.id, %DiscordUser{id: user1}, nil)
    refute_received {:notification_sink, _, _}
  end
end
