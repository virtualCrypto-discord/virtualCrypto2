defmodule VirtualCrypto.Repo.Migrations.DeleteAssetWhenAmountIsZero do
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
  def up() do
    execute(@trigger_function)
    execute(@trigger)
    execute("DELETE FROM assets WHERE assets.amount = 0;")
    create constraint("assets", "amount_must_be_positive", check: "amount > 0")
    drop constraint("assets", "amount_must_not_be_negative")
  end

  def down() do
    execute("DROP TRIGGER delete_asset_when_amount_is_zero ON assets;")
    execute("DROP FUNCTION delete_asset_by_id;")
    drop constraint("assets", "amount_must_be_positive")
    create constraint("assets", "amount_must_not_be_negative", check: "amount >= 0")
  end
end
