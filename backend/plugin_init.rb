require_relative 'lib/aspace_content_warnings_helper'
require_relative 'lib/aspace_content_warnings_serializer'
require_relative 'lib/aspace_content_warnings_ead'
require_relative 'lib/aspace_content_warnings_ead3'
require_relative 'lib/aspace_content_warnings_ead_overrides'
require_relative 'lib/aspace_content_warnings_ead3_overrides'
require_relative 'lib/aspace_patches'
require_relative 'lib/aspace_content_warnings_marc_serialize'

# allow for odd or scopecontent as the EAD/EAD3 note type
if AppConfig.has_key?(:aspace_content_warnings_note_type)
  unless ['odd', 'scopecontent'].include?(AppConfig[:aspace_content_warnings_note_type])
    AppConfig[:aspace_content_warnings_note_type] = 'scopecontent'
  end
else
  AppConfig[:aspace_content_warnings_note_type] = 'scopecontent'
end

# check if we should include HC in the exports
unless AppConfig.has_key?(:aspace_content_warnings_include_tags_in_exports) && [true, false].include?(AppConfig[:aspace_content_warnings_include_tags_in_exports]) 
  AppConfig[:aspace_content_warnings_include_tags_in_exports] = true
end

# Register our custom serialize steps.
if AppConfig[:aspace_content_warnings_include_tags_in_exports]
  EADSerializer.add_serialize_step(EADAspaceContentWarningsSerialize)
  EAD3Serializer.add_serialize_step(EAD3AspaceContentWarningsSerialize)
  MARCSerializer.add_decorator(AspaceContentWarningsMARCSerialize)
end
