require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Adding Offensive Content Tags Module plugin tables")

    create_table(:offensive_content_tag) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id
      Integer :resource_id
      Integer :archival_object_id
      Integer :digital_object_id

      DynamicEnum :offensive_content_tag_code_id
      
      MediumBlobField :description

      apply_mtime_columns
    end

    alter_table(:offensive_content_tag) do
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
    end

    create_editable_enum("offensive_content_tag_code", ["oct_race", "oct_hate", "oct_general", "oct_adult"])

  end

end
