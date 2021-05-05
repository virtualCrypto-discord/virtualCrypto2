defmodule VirtualCrypto.Repo.Migrations.ExtendAmountSizeAsBigint do
  use Ecto.Migration

  @trigger_function """
  CREATE FUNCTION delete_asset_by_id() RETURNS TRIGGER AS $delete_asset_by_id$
    BEGIN
      DELETE FROM assets WHERE assets.id = NEW.id;
      RETURN NULL;
    END;
  $delete_asset_by_id$ LANGUAGE plpgsql;
  """
  @trigger """
  CREATE TRIGGER delete_asset_when_amount_is_zero
    BEFORE INSERT OR UPDATE OF amount
    ON assets
    FOR EACH ROW
    WHEN ( NEW.amount = 0 )
    EXECUTE PROCEDURE delete_asset_by_id();
  """

  def change do
    execute("DROP TRIGGER delete_asset_when_amount_is_zero ON assets;")
    execute("DROP FUNCTION delete_asset_by_id;")

    alter table(:assets) do
      remove :status
      modify :amount, :bigint
    end

    alter table(:money_payment_historys) do
      modify :amount, :bigint
    end

    alter table(:money_given_historys) do
      modify :amount, :bigint
    end

    alter table(:claims) do
      modify :amount, :bigint
    end

    alter table(:info) do
      remove :status
      modify :pool_amount, :bigint
    end

    execute(@trigger_function)
    execute(@trigger)
  end
end
