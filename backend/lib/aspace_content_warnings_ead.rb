require 'aspace_logger'

class AspaceContentWarningsEAD < EADSerializer

  def serialize_aspace_content_warnings(data, xml, fragments)
    if AppConfig[:plugins].include?('aspace_content_warnings')
      if data.content_warnings && data.content_warnings.length > 0
        xml.send(AppConfig[:aspace_content_warnings_note_type]) {
          xml.head {
            sanitize_mixed_content(I18n.t("content_warning.section_title"), xml, fragments)
          }
          if AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['general_only'] == true
            cw_text = AspaceContentWarningsEADHelper.general_cw_text
            xml.p {
              sanitize_mixed_content(cw_text, xml, fragments)
            }
          else
            data.content_warnings.each do |cw|
              xml.p {
                sanitize_mixed_content(AspaceContentWarningsEADHelper.assemble_content_warning_text(cw), xml, fragments)
              }
            end
          end
          }
      end
    end
  end

  def serialize_aspace_content_warnings_for_digital_objects(digital_object, xml, fragments)
    if AppConfig[:plugins].include?('aspace_content_warnings')
      if digital_object['content_warnings'] && digital_object['content_warnings'].length > 0
        xml.note {
          xml.p {
            sanitize_mixed_content(I18n.t("content_warning.section_title"), xml, fragments)
          }
          if AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['general_only'] == true
            xml.p {
              sanitize_mixed_content(AspaceContentWarningsEADHelper.general_cw_text, xml, fragments)
            } 
          else
            digital_object['content_warnings'].each do |cw|
              xml.p {
                sanitize_mixed_content(AspaceContentWarningsEADHelper.assemble_content_warning_text(cw), xml, fragments)
              }
            end
          end
        }
      end
    end
  end

end
