defmodule VirtualCrypto.Repo.Migrations.ClaimMetadata do
  use Ecto.Migration

  @function_metadata_limitation """
  CREATE FUNCTION metadata_limitation(json_obj in jsonb)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
  AS
  $body$
  DECLARE
  entry RECORD;
  key_count INTEGER;
  BEGIN
    key_count := 0;
    FOR entry IN (
      SELECT * FROM jsonb_each(json_obj)
    )
    LOOP
      key_count := key_count + 1;
      IF length(entry.key::text) > 40 OR jsonb_typeof(entry.value) != 'string' OR length(entry.value#>>'{}') > 500 OR key_count > 50 THEN
        RETURN FALSE;
      END IF;
    END LOOP;
    RETURN TRUE;
  END;
  $body$;
  """
  @trigger_function_before_update """
  CREATE FUNCTION metadata_limitation_trigger() RETURNS TRIGGER AS $metadata_limitation_trigger$
    BEGIN
      RAISE check_violation;
    END;
  $metadata_limitation_trigger$ LANGUAGE plpgsql;
  """
  @trigger_before_update """
  CREATE TRIGGER metadata_limitation
    BEFORE UPDATE OF metadata
    ON claim_metadata
    FOR EACH ROW
    WHEN (NOT metadata_limitation(NEW.metadata))
    EXECUTE PROCEDURE metadata_limitation_trigger();
  """

  @trigger_function_after_insert """
  CREATE FUNCTION claim_metadata_strip_nulls() RETURNS TRIGGER AS $claim_metadata_strip_nulls$
    BEGIN
      UPDATE claim_metadata SET metadata=jsonb_strip_nulls(NEW.metadata) WHERE id=NEW.id;
      RETURN NULL;
    END;
  $claim_metadata_strip_nulls$ LANGUAGE plpgsql;
  """

  @trigger_after_insert """
  CREATE TRIGGER strip_nulls_after_insert
  AFTER INSERT
  ON claim_metadata
  FOR EACH ROW
  EXECUTE PROCEDURE claim_metadata_strip_nulls();
  """
  @trigger_function_remove_claim_metadata_entry """
  CREATE FUNCTION claim_metadata_remove_row() RETURNS TRIGGER AS $claim_metadata_remove_row$
  BEGIN
    DELETE FROM claim_metadata WHERE id=NEW.id;
    RETURN NULL;
  END;
  $claim_metadata_remove_row$ LANGUAGE plpgsql;
  """
  # must execute last!
  @trigger_remove_entry_if_empty """
  CREATE TRIGGER _remove_entry_if_empty
  BEFORE UPDATE OF metadata
  ON claim_metadata
  FOR EACH ROW
  WHEN ('{}'::jsonb @> NEW.metadata)
  EXECUTE PROCEDURE claim_metadata_remove_row();
  """

  def up do
    create table(:claim_metadata) do
      add(:claim_id, references(:claims, on_delete: :delete_all), null: false)
      add(:claimant_user_id, references(:users, on_delete: :delete_all), null: false)
      add(:payer_user_id, references(:users, on_delete: :delete_all), null: false)
      add(:owner_user_id, references(:users, on_delete: :delete_all), null: false)
      add(:metadata, :map, null: false)
    end

    execute("""
      ALTER TABLE claims
      ADD CONSTRAINT claims_unique_ordered_claim_metadata_fk UNIQUE (id, claimant_user_id, payer_user_id);
    """)

    execute("""
      ALTER TABLE claim_metadata
      ADD CONSTRAINT claim_metadata_fk
      FOREIGN KEY (claim_id, claimant_user_id, payer_user_id)
      REFERENCES claims(id, claimant_user_id, payer_user_id)
      ON DELETE CASCADE
    """)

    create(
      constraint(:claim_metadata, "metadata_owner_is_must_related_user",
        check: "owner_user_id IN (claimant_user_id,payer_user_id)"
      )
    )

    create(
      constraint(:claim_metadata, "metadata_must_be_object",
        check: "jsonb_typeof(metadata) = 'object'"
      )
    )

    create(unique_index(:claim_metadata, [:claim_id, :owner_user_id]))
    execute(@function_metadata_limitation)
    execute(@trigger_function_before_update)
    execute(@trigger_before_update)
    execute(@trigger_function_after_insert)
    execute(@trigger_after_insert)
    execute(@trigger_function_remove_claim_metadata_entry)
    execute(@trigger_remove_entry_if_empty)
  end

  def down do
    execute("DROP TABLE claim_metadata")
    execute("ALTER TABLE claims DROP CONSTRAINT claims_unique_ordered_claim_metadata_fk")

    execute("DROP FUNCTION metadata_limitation_trigger;")
    execute("DROP FUNCTION metadata_limitation(jsonb);")
    execute("DROP FUNCTION claim_metadata_strip_nulls;")
    execute("DROP FUNCTION claim_metadata_remove_row;")
  end
end
