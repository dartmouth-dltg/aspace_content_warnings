ArchivesSpace::Application.config.after_initialize do
  # only add faceting if configured
  if AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['staff_faceting'] == true
    SearchResultData.class_eval do
      self.singleton_class.send(:alias_method, :BASE_FACETS_pre_content_warnings, :BASE_FACETS)
      def self.BASE_FACETS
        if AppConfig[:aspace_content_warnings]['general_only'] == true
          self.BASE_FACETS_pre_content_warnings << "content_warnings_general_u_sbool"
        else
          self.BASE_FACETS_pre_content_warnings << "content_warnings_u_sstr"
        end
      end
    end
  end

  JSONModel(:content_warning)

end
