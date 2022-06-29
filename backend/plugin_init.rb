require_relative 'lib/aspace_content_warnings_ead'

# allow for odd or scopecontent as the EAD/EAD3 note type
if AppConfig.has_key?(:aspace_content_warnings_note_type)
  unless ['odd', 'scopcontent'].include?(AppConfig[:aspace_content_warnings_note_type])
    AppConfig[:aspace_content_warnings_note_type] = 'odd'
  end
else
  AppConfig[:aspace_content_warnings_note_type] = 'odd'
end
