defmodule VirtualCrypto.Repo.Migrations.AddNameUniqueUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:info, :name)
  end
end
