defmodule VirtualCrypto.Repo.Migrations.WebhookUrl do
  use Ecto.Migration

  def loop() do
    case repo().query!("MOVE 1 cur") do
      %{num_rows: 1} ->
        {:ECPrivateKey, 1, private_key, _params, public_key, :asn1_NOVALUE} =
          :public_key.generate_key({:namedCurve, :ed25519})

        repo().query!(
          "UPDATE applications SET private_key = $1::bytea,public_key = $2::bytea WHERE CURRENT OF cur",
          [private_key, public_key]
        )

        loop()

      _ ->
        nil
    end
  end

  def insert_key() do
    repo().query!("DECLARE cur CURSOR FOR SELECT FROM applications")
    loop()
    repo().query!("CLOSE cur")
  end

  def up do
    alter table(:applications) do
      add(:webhook_url, :string, size: 2048, null: true)
      add(:public_key, :binary, null: true)
      add(:private_key, :binary, null: true)
    end

    execute(&insert_key/0)

    alter table(:applications) do
      modify(:public_key, :binary, null: false)
      modify(:private_key, :binary, null: false)
    end
  end

  def down do
    alter table(:applications) do
      remove(:webhook_url)
      remove(:public_key)
      remove(:private_key)
    end
  end
end
