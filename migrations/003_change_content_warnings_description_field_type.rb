require 'db/migrations/utils'

Sequel.migration do

  up do
    $stderr.puts("Changing Content Warning description field from MediumBlob to Text")

    alter_table(:content_warning) do
      set_column_type(:description, 'text')
    end

  end

end
