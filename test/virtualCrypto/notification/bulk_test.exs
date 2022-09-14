defmodule VirtualCrypto.Test.Bulk do
  use VirtualCrypto.DataCase, async: true
  import VirtualCrypto.EnvironmentBootstrapper, only: [setup_money: 1]
  import VirtualCryptoTest.Notification.Setup
  alias VirtualCrypto.Exterior.User.Discord, as: DiscordUser
  setup :setup_money

  test "approve multiple claims by the same claimant", %{unit: unit, user1: user1, user2: user2} do
    {:ok, claim1} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    {:ok, claim2} =
      setup_claim(%{unit: unit, amount: 200, metadata: nil, receiver: user1, payer: user2})

    assert {:ok, _} =
             VirtualCrypto.Money.update_claims(
               [
                 %{
                   id: claim1.claim.id,
                   status: "approved"
                 },
                 %{
                   id: claim2.claim.id,
                   status: "approved"
                 }
               ],
               %DiscordUser{id: user2}
             )

    assert_received {:notification_sink, exterior, events}
    _ = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)

    %{payer: payer, currency: currency} = claim1

    assert [
             %{
               amount: "100",
               currency: %{
                 id: currency.id,
                 name: currency.name,
                 unit: currency.unit,
               },
               id: claim1.claim.id,
               metadata: %{"x" => "y"},
               payer: %{
                 discord: %{id: to_string(payer.discord_id)},
                 id: payer.id
               },
               status: :approved,
               updated_at: (events |> Enum.at(0)).updated_at
             },
             %{
               amount: "200",
               currency: %{
                 id: currency.id,
                 name: currency.name,
                 unit: currency.unit,
               },
               id: claim2.claim.id,
               metadata: %{},
               payer: %{
                 discord: %{id: to_string(payer.discord_id)},
                 id: payer.id
               },
               status: :approved,
               updated_at: (events |> Enum.at(0)).updated_at
             }
           ]
           |> MapSet.new() == events |> MapSet.new()

    assert %DateTime{} = (events |> Enum.at(0)).updated_at
    assert "Etc/UTC" == (events |> Enum.at(0)).updated_at.time_zone

    assert %DateTime{} = (events |> Enum.at(1)).updated_at
    assert "Etc/UTC" == (events |> Enum.at(1)).updated_at.time_zone
  end

  test "deny multiple claims by the same claimant", %{unit: unit, user1: user1, user2: user2} do
    {:ok, claim1} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    {:ok, claim2} =
      setup_claim(%{unit: unit, amount: 200, metadata: nil, receiver: user1, payer: user2})

    assert {:ok, _} =
             VirtualCrypto.Money.update_claims(
               [
                 %{
                   id: claim1.claim.id,
                   status: "denied"
                 },
                 %{
                   id: claim2.claim.id,
                   status: "denied"
                 }
               ],
               %DiscordUser{id: user2}
             )

    assert_received {:notification_sink, exterior, events}
    _ = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)

    %{payer: payer, currency: currency} = claim1

    assert [
             %{
               amount: "100",
               currency: %{
                 id: currency.id,
                 name: currency.name,
                 unit: currency.unit,
               },
               id: claim1.claim.id,
               metadata: %{"x" => "y"},
               payer: %{
                 discord: %{id: to_string(payer.discord_id)},
                 id: payer.id
               },
               status: :denied,
               updated_at: (events |> Enum.at(0)).updated_at
             },
             %{
               amount: "200",
               currency: %{
                 id: currency.id,
                 name: currency.name,
                 unit: currency.unit,
               },
               id: claim2.claim.id,
               metadata: %{},
               payer: %{
                 discord: %{id: to_string(payer.discord_id)},
                 id: payer.id
               },
               status: :denied,
               updated_at: (events |> Enum.at(0)).updated_at
             }
           ]
           |> MapSet.new() == events |> MapSet.new()

    assert %DateTime{} = (events |> Enum.at(0)).updated_at
    assert "Etc/UTC" == (events |> Enum.at(0)).updated_at.time_zone

    assert %DateTime{} = (events |> Enum.at(1)).updated_at
    assert "Etc/UTC" == (events |> Enum.at(1)).updated_at.time_zone
  end

  test "approve and deny multiple claims by the same claimant", %{
    unit: unit,
    user1: user1,
    user2: user2
  } do
    {:ok, claim1} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    {:ok, claim2} =
      setup_claim(%{unit: unit, amount: 200, metadata: nil, receiver: user1, payer: user2})

    assert {:ok, _} =
             VirtualCrypto.Money.update_claims(
               [
                 %{
                   id: claim1.claim.id,
                   status: "approved"
                 },
                 %{
                   id: claim2.claim.id,
                   status: "denied"
                 }
               ],
               %DiscordUser{id: user2}
             )

    assert_received {:notification_sink, exterior, events}
    _ = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior)

    %{payer: payer, currency: currency} = claim1

    assert [
             %{
               amount: "100",
               currency: %{
                 id: currency.id,
                 name: currency.name,
                 unit: currency.unit,
               },
               id: claim1.claim.id,
               metadata: %{"x" => "y"},
               payer: %{
                 discord: %{id: to_string(payer.discord_id)},
                 id: payer.id
               },
               status: :approved,
               updated_at: (events |> Enum.at(0)).updated_at
             },
             %{
               amount: "200",
               currency: %{
                 id: currency.id,
                 name: currency.name,
                 unit: currency.unit,
               },
               id: claim2.claim.id,
               metadata: %{},
               payer: %{
                 discord: %{id: to_string(payer.discord_id)},
                 id: payer.id
               },
               status: :denied,
               updated_at: (events |> Enum.at(0)).updated_at
             }
           ]
           |> MapSet.new() == events |> MapSet.new()

    assert %DateTime{} = (events |> Enum.at(0)).updated_at
    assert "Etc/UTC" == (events |> Enum.at(0)).updated_at.time_zone

    assert %DateTime{} = (events |> Enum.at(1)).updated_at
    assert "Etc/UTC" == (events |> Enum.at(1)).updated_at.time_zone
  end

  test "approve multiple claims by the different claimant", %{
    unit: unit,
    user1: user1,
    user2: user2
  } do
    {:ok, claim1} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    {:ok, claim2} =
      setup_claim(%{unit: unit, amount: 200, metadata: nil, receiver: 123, payer: user2})

    assert {:ok, _} =
             VirtualCrypto.Money.update_claims(
               [
                 %{
                   id: claim1.claim.id,
                   status: "approved"
                 },
                 %{
                   id: claim2.claim.id,
                   status: "approved"
                 }
               ],
               %DiscordUser{id: user2}
             )

    assert_received {:notification_sink, exterior1, [event1]}
    assert_received {:notification_sink, exterior2, [event2]}
    receiver1 = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior1)

    receiver2 = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior2)

    %{payer: payer, currency: currency} = claim1

    assert [
             {user1,
              %{
                amount: "100",
                currency: %{
                  id: currency.id,
                  name: currency.name,
                  unit: currency.unit,
                },
                id: claim1.claim.id,
                metadata: %{"x" => "y"},
                payer: %{
                  discord: %{id: to_string(payer.discord_id)},
                  id: payer.id
                },
                status: :approved,
                updated_at: event1.updated_at
              }},
             {
               123,
               %{
                 amount: "200",
                 currency: %{
                   id: currency.id,
                   name: currency.name,
                   unit: currency.unit,
                 },
                 id: claim2.claim.id,
                 metadata: %{},
                 payer: %{
                   discord: %{id: to_string(payer.discord_id)},
                   id: payer.id
                 },
                 status: :approved,
                 updated_at: event2.updated_at
               }
             }
           ]
           |> MapSet.new() ==
             [{receiver1.discord_id, event1}, {receiver2.discord_id, event2}] |> MapSet.new()

    assert %DateTime{} = event1.updated_at
    assert "Etc/UTC" == event1.updated_at.time_zone

    assert %DateTime{} = event2.updated_at
    assert "Etc/UTC" == event2.updated_at.time_zone
  end

  test "deny multiple claims by the different claimant", %{
    unit: unit,
    user1: user1,
    user2: user2
  } do
    {:ok, claim1} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    {:ok, claim2} =
      setup_claim(%{unit: unit, amount: 200, metadata: nil, receiver: 123, payer: user2})

    assert {:ok, _} =
             VirtualCrypto.Money.update_claims(
               [
                 %{
                   id: claim1.claim.id,
                   status: "denied"
                 },
                 %{
                   id: claim2.claim.id,
                   status: "denied"
                 }
               ],
               %DiscordUser{id: user2}
             )

    assert_received {:notification_sink, exterior1, [event1]}
    assert_received {:notification_sink, exterior2, [event2]}
    receiver1 = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior1)

    receiver2 = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior2)

    %{payer: payer, currency: currency} = claim1

    assert [
             {user1,
              %{
                amount: "100",
                currency: %{
                  id: currency.id,
                  name: currency.name,
                  unit: currency.unit,
                },
                id: claim1.claim.id,
                metadata: %{"x" => "y"},
                payer: %{
                  discord: %{id: to_string(payer.discord_id)},
                  id: payer.id
                },
                status: :denied,
                updated_at: event1.updated_at
              }},
             {
               123,
               %{
                 amount: "200",
                 currency: %{
                   id: currency.id,
                   name: currency.name,
                   unit: currency.unit,
                 },
                 id: claim2.claim.id,
                 metadata: %{},
                 payer: %{
                   discord: %{id: to_string(payer.discord_id)},
                   id: payer.id
                 },
                 status: :denied,
                 updated_at: event2.updated_at
               }
             }
           ]
           |> MapSet.new() ==
             [{receiver1.discord_id, event1}, {receiver2.discord_id, event2}] |> MapSet.new()

    assert %DateTime{} = event1.updated_at
    assert "Etc/UTC" == event1.updated_at.time_zone

    assert %DateTime{} = event2.updated_at
    assert "Etc/UTC" == event2.updated_at.time_zone
  end

  test "mixed operations multiple claims by the different claimant", %{
    unit: unit,
    user1: user1,
    user2: user2
  } do
    {:ok, claim1} =
      setup_claim(%{
        unit: unit,
        amount: 100,
        metadata: %{"x" => "y"},
        receiver: user1,
        payer: user2
      })

    {:ok, claim2} =
      setup_claim(%{unit: unit, amount: 200, metadata: nil, receiver: 123, payer: user2})

    {:ok, claim3} =
      setup_claim(%{unit: unit, amount: 100, metadata: nil, receiver: user2, payer: user1})

    assert {:ok, _} =
             VirtualCrypto.Money.update_claims(
               [
                 %{
                   id: claim1.claim.id,
                   status: "approved"
                 },
                 %{
                   id: claim2.claim.id,
                   status: "denied"
                 },
                 %{
                   id: claim3.claim.id,
                   status: "canceled"
                 }
               ],
               %DiscordUser{id: user2}
             )

    assert_received {:notification_sink, exterior1, [event1]}
    assert_received {:notification_sink, exterior2, [event2]}
    receiver1 = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior1)

    receiver2 = VirtualCrypto.Exterior.User.Resolvable.resolve(exterior2)

    %{payer: payer, currency: currency} = claim1

    assert [
             {user1,
              %{
                amount: "100",
                currency: %{
                  id: currency.id,
                  name: currency.name,
                  unit: currency.unit,
                },
                id: claim1.claim.id,
                metadata: %{"x" => "y"},
                payer: %{
                  discord: %{id: to_string(payer.discord_id)},
                  id: payer.id
                },
                status: :approved,
                updated_at: event1.updated_at
              }},
             {
               123,
               %{
                 amount: "200",
                 currency: %{
                   id: currency.id,
                   name: currency.name,
                   unit: currency.unit,
                 },
                 id: claim2.claim.id,
                 metadata: %{},
                 payer: %{
                   discord: %{id: to_string(payer.discord_id)},
                   id: payer.id
                 },
                 status: :denied,
                 updated_at: event2.updated_at
               }
             }
           ]
           |> MapSet.new() ==
             [{receiver1.discord_id, event1}, {receiver2.discord_id, event2}] |> MapSet.new()

    assert %DateTime{} = event1.updated_at
    assert "Etc/UTC" == event1.updated_at.time_zone

    assert %DateTime{} = event2.updated_at
    assert "Etc/UTC" == event2.updated_at.time_zone
  end
end
