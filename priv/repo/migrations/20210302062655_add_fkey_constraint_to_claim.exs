defmodule VirtualCrypto.Repo.Migrations.AddFkeyConstraintToClaim do
  use Ecto.Migration

  def change do
    alter table(:claims) do
      modify :claimant_user_id, references(:users), null: false
      modify :payer_user_id, references(:users), null: false
      modify :money_info_id, references(:info), null: false
    end
  end
end
