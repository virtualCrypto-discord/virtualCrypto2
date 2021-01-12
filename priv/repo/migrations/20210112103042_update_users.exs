defmodule VirtualCrypto.Repo.Migrations.UpdateUsers do
  use Ecto.Migration

  def change do
    execute("CREATE SEQUENCE users_id_seq OWNED BY users.id;")

    alter table(:users) do
      modify :id,:id,default: fragment("nextval('users_id_seq'::regclass)")
    end

  end
end
