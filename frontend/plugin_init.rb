ArchivesSpace::Application.config.after_initialize do
  # only add faceting if configured
  if AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['staff_faceting'] == true
    if AppConfig[:aspace_content_warnings]['general_only'] == true
      Plugins::add_search_base_facets('content_warnings_general_u_sbool')
    else
      Plugins::add_search_base_facets('content_warnings_u_sstr')
    end
  end

  JSONModel(:content_warning)

end
