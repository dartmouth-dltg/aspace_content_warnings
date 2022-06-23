require 'uri'

Rails.application.config.after_initialize do

  # only add faceting if configured
  if AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['public_faceting'] == true
    Searchable.module_eval do
      alias_method :pre_aspace_content_warnings_set_up_advanced_search, :set_up_advanced_search
      def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
        if AppConfig[:aspace_content_warnings]['general_only'] == true
          default_facets << 'content_warnings_general_u_sbool'
        else
          default_facets << 'content_warnings_u_sstr'
        end
        pre_aspace_content_warnings_set_up_advanced_search(default_types, default_facets, default_search_opts, params)
      end
    end
  end

  # check if an external link has been set
  unless AppConfig.has_key?(:aspace_content_warnings_external_link)
    AppConfig[:aspace_content_warnings_external_link] = nil
  end

  # check if the public is allowed to submit suggestions
  unless AppConfig.has_key?(:aspace_content_warnings_allow_pui_submit)
    AppConfig[:aspace_content_warnings_allow_pui_submit] = nil
  end

end
