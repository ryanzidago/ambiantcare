defmodule Ambiantcare.Repo.Migrations.TemplateChangeFieldType do
  use Ecto.Migration

   def up do
    # First remove the default value
    execute "ALTER TABLE medical_note_templates ALTER COLUMN fields DROP DEFAULT"

    # Then change the type
    execute """
    ALTER TABLE medical_note_templates
    ALTER COLUMN fields TYPE jsonb
    USING jsonb_build_object('fields', COALESCE(fields, '{}'));
    """

    # Set new default if needed
    execute "ALTER TABLE medical_note_templates ALTER COLUMN fields SET DEFAULT '{}'::jsonb"
  end

  def down do
    execute "ALTER TABLE medical_note_templates ALTER COLUMN fields DROP DEFAULT"

    execute """
    ALTER TABLE medical_note_templates
    ALTER COLUMN fields TYPE jsonb[]
    USING ARRAY[fields];
    """

    execute "ALTER TABLE medical_note_templates ALTER COLUMN fields SET DEFAULT '{}'::jsonb[]"
  end
end
