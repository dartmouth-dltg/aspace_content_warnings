Rails.application.config.after_initialize do
  
  # only add faceting if configured
  if AppConfig.has_key?(:aspace_offensive_content_tags) && AppConfig[:aspace_offensive_content_tags]['public_faceting'] == true
    Searchable.module_eval do
      alias_method :pre_aspace_offensive_content_tags_set_up_advanced_search, :set_up_advanced_search
      def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
        default_facets << 'offensive_content_tags_u_sstr'
        pre_aspace_offensive_content_tags_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
      end
    end
  end
end