require 'uri'

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
  
  # check if an external link has been set
  unless AppConfig.has_key?(:aspace_offensive_content_tags_external_link)
    AppConfig[:aspace_offensive_content_tags_external_link] = nil
  end
  
  # check if the public is allowed to submit suggestions
  unless AppConfig.has_key?(:aspace_offensive_content_allow_pui_submit)
    AppConfig[:aspace_offensive_content_allow_pui_submit] = nil
  end
  
end