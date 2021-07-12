ArchivesSpace::Application.config.after_initialize do
  # only add faceting if configured
  if AppConfig.has_key?(:aspace_offensive_content_tags) && AppConfig[:aspace_offensive_content_tags]['staff_faceting'] == true
    SearchResultData.class_eval do
      self.singleton_class.send(:alias_method, :BASE_FACETS_pre_offensive_content_tags, :BASE_FACETS)
      def self.BASE_FACETS
        self.BASE_FACETS_pre_offensive_content_tags << "offensive_content_tags_u_sstr"
      end
    end
  end
  
  JSONModel(:offensive_content_tag)

end
