# keep a handle on the source record so the MARC decorator can read content_warnings
class MARCModel < ASpaceExport::ExportModel
  attr_reader :aspace_record

  class << self
    # guard: backend plugin files are in main.rb's also_reload list, so this file can load twice
    unless method_defined?(:aspace_content_warnings_from_aspace_object)
      alias_method :aspace_content_warnings_from_aspace_object, :from_aspace_object

      def from_aspace_object(obj, opts = {})
        marc = aspace_content_warnings_from_aspace_object(obj, opts)
        marc.instance_variable_set(:@aspace_record, obj)
        marc
      end
    end
  end
end
