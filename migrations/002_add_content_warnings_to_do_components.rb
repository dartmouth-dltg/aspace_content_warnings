require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Adding Content Warnings to digital object components")

    alter_table(:content_warning) do
      add_column(:digital_object_component_id, :integer, :null => true)
    end
    alter_table(:content_warning) do
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

  end

end
