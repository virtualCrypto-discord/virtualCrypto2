defmodule VirtualCrypto.Repo.Migrations.CreateStringClaimIdIndex do
  use Ecto.Migration

  def up do
    execute("CREATE UNIQUE INDEX text_claims_id ON claims ((id::text));")
  end

  def down do
    execute("DROP INDEX text_claims_id;")
  end
end
