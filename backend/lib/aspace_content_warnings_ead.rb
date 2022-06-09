require 'securerandom'
require 'aspace_logger'
class EADSerializer < ASpaceExport::Serializer

  # We're patching this method to deal with the content warnings
  # Lot's of copy pasta for one line....sigh

  def stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      ead_attributes = {
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd',
        'xmlns:xlink' => 'http://www.w3.org/1999/xlink'
      }

      if data.publish === false
        ead_attributes['audience'] = 'internal'
      end

      xml.ead( ead_attributes ) {

        xml.text (
          @stream_handler.buffer { |xml, new_fragments|
            serialize_eadheader(data, xml, new_fragments)
          })

        atts = {:level => data.level, :otherlevel => data.other_level}
        atts.reject! {|k, v| v.nil?}

        xml.archdesc(atts) {

          xml.did {

            if (val = data.repo.name)
              xml.repository {
                xml.corpname { sanitize_mixed_content(val, xml, @fragments) }
              }
            end

            if (val = data.title)
              xml.unittitle { sanitize_mixed_content(val, xml, @fragments) }
            end

            serialize_origination(data, xml, @fragments)

            xml.unitid (0..3).map {|i| data.send("id_#{i}")}.compact.join('.')

            if @include_unpublished
              data.external_ids.each do |exid|
                xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
              end
            end

            handle_arks(data, xml)

            serialize_extents(data, xml, @fragments)

            serialize_dates(data, xml, @fragments)

            serialize_did_notes(data, xml, @fragments)

            if (languages = data.lang_materials)
              serialize_languages(languages, xml, @fragments)
            end

            data.instances_with_sub_containers.each do |instance|
              serialize_container(instance, xml, @fragments)
            end

            EADSerializer.run_serialize_step(data, xml, @fragments, :did)

          }# </did>

          # This is it. The patch. All one lines of it
          serialize_aspace_content_warnings_ead(data, xml, @fragments)
          # end the patch

          data.digital_objects.each do |dob|
            serialize_digital_object(dob, xml, @fragments)
          end

          serialize_nondid_notes(data, xml, @fragments)

          serialize_bibliographies(data, xml, @fragments)

          serialize_indexes(data, xml, @fragments)

          serialize_controlaccess(data, xml, @fragments)

          EADSerializer.run_serialize_step(data, xml, @fragments, :archdesc)

          xml.dsc {

            data.children_indexes.each do |i|
              xml.text(
                @stream_handler.buffer {|xml, new_fragments|
                  serialize_child(data.get_child(i), xml, new_fragments)
                }
              )
            end
          }
        }
      }
    end
    doc.doc.root.add_namespace nil, 'urn:isbn:1-931666-22-9'

    Enumerator.new do |y|
      @stream_handler.stream_out(doc, @fragments, y)
    end
  end

  def serialize_child(data, xml, fragments, c_depth = 1)
    return if data["publish"] === false && !@include_unpublished
    return if data["suppressed"] === true

    tag_name = @use_numbered_c_tags ? :"c#{c_depth.to_s.rjust(2, '0')}" : :c

    atts = {:level => data.level, :otherlevel => data.other_level, :id => prefix_id(data.ref_id)}

    if data.publish === false
      atts[:audience] = 'internal'
    end

    atts.reject! {|k, v| v.nil?}
    xml.send(tag_name, atts) {

      xml.did {
        if (val = data.title)
          xml.unittitle { sanitize_mixed_content( val, xml, fragments) }
        end

        if !data.component_id.nil? && !data.component_id.empty?
          xml.unitid data.component_id
        end

        handle_arks(data, xml)

        if @include_unpublished
          data.external_ids.each do |exid|
            xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
          end
        end

        serialize_origination(data, xml, fragments)
        serialize_extents(data, xml, fragments)
        serialize_dates(data, xml, fragments)
        serialize_did_notes(data, xml, fragments)

        if (languages = data.lang_materials)
          serialize_languages(languages, xml, fragments)
        end

        EADSerializer.run_serialize_step(data, xml, fragments, :did)

        data.instances_with_sub_containers.each do |instance|
          serialize_container(instance, xml, @fragments)
        end

        if @include_daos
          data.instances_with_digital_objects.each do |instance|
            serialize_digital_object(instance['digital_object']['_resolved'], xml, fragments)
          end
        end
      }

      # This is it. The patch. All one line of it for AOs
      serialize_aspace_content_warnings_ead(data, xml, @fragments)
      # end the patch

      serialize_nondid_notes(data, xml, fragments)

      serialize_bibliographies(data, xml, fragments)

      serialize_indexes(data, xml, fragments)

      serialize_controlaccess(data, xml, fragments)

      EADSerializer.run_serialize_step(data, xml, fragments, :archdesc)

      data.children_indexes.each do |i|
        xml.text(
          @stream_handler.buffer {|xml, new_fragments|
            serialize_child(data.get_child(i), xml, new_fragments, c_depth + 1)
          }
        )
      end
    }
  end

  # custom method to include Local Contexts data
  def serialize_aspace_content_warnings_ead(data, xml, fragments)
    if AppConfig[:plugins].include?('aspace_content_warnings')
      if data.content_warnings && data.content_warnings.length > 0
        xml.odd {
          xml.head {
            sanitize_mixed_content(I18n.t("content_warning.section_title") , xml, fragments)
          }
          data.content_warnings.each do |cw|
            cw_type = cw['content_warning_code']
            if cw['description']
              cw_description = cw['description']
            else
              cw_description = I18n.t("content_warning_description.#{cw_type}")
            end
            cw_text = I18n.t("enumerations.content_warning_code.#{cw_type}") + ": " + cw_description
            xml.p {
              sanitize_mixed_content(cw_text , xml, fragments)
            }
          end
          }
      end
    end
  end

end

class EAD3Serializer < EADSerializer
  def stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @include_daos = data.include_daos?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      begin
        ead_attributes = {}

        if data.publish === false
          ead_attributes['audience'] = 'internal'
        end

        xml.ead( ead_attributes ) {

          xml.text (
            @stream_handler.buffer { |xml, new_fragments|
              serialize_control(data, xml, new_fragments)
            }
          )

          atts = {:level => data.level, :otherlevel => data.other_level}
          atts.reject! {|k, v| v.nil?}

          xml.archdesc(atts) {

            xml.did {

              unless data.title.nil?
                xml.unittitle { sanitize_mixed_content(data.title, xml, @fragments) }
              end

              xml.unitid (0..3).map { |i| data.send("id_#{i}") }.compact.join('.')

              handle_arks(data, xml)

              unless data.repo.nil? || data.repo.name.nil?
                xml.repository {
                  xml.corpname {
                    xml.part {
                      sanitize_mixed_content(data.repo.name, xml, @fragments)
                    }
                  }
                }
              end

              unless (languages = data.lang_materials).empty?
                serialize_languages(languages, xml, @fragments)
              end

              data.instances_with_sub_containers.each do |instance|
                serialize_container(instance, xml, @fragments)
              end

              serialize_extents(data, xml, @fragments)

              serialize_dates(data, xml, @fragments)

              serialize_did_notes(data, xml, @fragments)

              serialize_origination(data, xml, @fragments)

              if @include_unpublished
                data.external_ids.each do |exid|
                  xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
                end
              end


              EADSerializer.run_serialize_step(data, xml, @fragments, :did)

          # This is it. The patch. All one line of it
          serialize_aspace_content_warnings_ead3(data, xml, @fragments)
          # end the patch

          # Change from EAD 2002: dao must be children of did in EAD3, not archdesc
           data.digital_objects.each do |dob|
             serialize_digital_object(dob, xml, @fragments)
           end

         }# </did>

         serialize_nondid_notes(data, xml, @fragments)

         serialize_bibliographies(data, xml, @fragments)

         serialize_indexes(data, xml, @fragments)

         serialize_controlaccess(data, xml, @fragments)

         EADSerializer.run_serialize_step(data, xml, @fragments, :archdesc)

         xml.dsc {

           data.children_indexes.each do |i|
             xml.text( @stream_handler.buffer {
               |xml, new_fragments| serialize_child(data.get_child(i), xml, new_fragments)
               }
             )
           end
         }
       }
     }

      rescue => e
        xml.text "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF YOUR RESOURCE. THE FOLLOWING INFORMATION MAY HELP:\n
                 MESSAGE: #{e.message.inspect}  \n
                 TRACE: #{e.backtrace.inspect} \n "
      end
    end

    # Add xml-model for rng
    # Make this conditional if XSD or DTD are requested
    xmlmodel_content = 'href="https://raw.githubusercontent.com/SAA-SDT/EAD3/master/ead3.rng"
      type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"'

    xmlmodel = Nokogiri::XML::ProcessingInstruction.new(builder.doc, "xml-model", xmlmodel_content)
    builder.doc.root.add_previous_sibling(xmlmodel)
    builder.doc.root.add_namespace nil, 'http://ead3.archivists.org/schema/'

    Enumerator.new do |y|
      @stream_handler.stream_out(builder, @fragments, y)
    end
  end # END stream

  def serialize_child(data, xml, fragments, c_depth = 1)
    begin
      return if data["publish"] === false && !@include_unpublished
      return if data["suppressed"] === true

      tag_name = @use_numbered_c_tags ? :"c#{c_depth.to_s.rjust(2, '0')}" : :c

      atts = {:level => data.level, :otherlevel => data.other_level, :id => prefix_id(data.ref_id)}

      if data.publish === false
        atts[:audience] = 'internal'
      end

      atts.reject! {|k, v| v.nil?}
      xml.send(tag_name, atts) {

        xml.did {
          if (val = data.title)
            xml.unittitle { sanitize_mixed_content( val, xml, fragments) }
          end

          handle_arks(data, xml)

          if !data.component_id.nil? && !data.component_id.empty?
            xml.unitid data.component_id
          end

          if @include_unpublished
            data.external_ids.each do |exid|
              xml.unitid ({ "audience" => "internal", "type" => exid['source'], "identifier" => exid['external_id']}) { xml.text exid['external_id']}
            end
          end

          serialize_origination(data, xml, fragments)
          serialize_extents(data, xml, fragments)
          serialize_dates(data, xml, fragments)
          serialize_did_notes(data, xml, fragments)

          unless (languages = data.lang_materials).empty?
            serialize_languages(languages, xml, fragments)
          end

          EADSerializer.run_serialize_step(data, xml, fragments, :did)

          data.instances_with_sub_containers.each do |instance|
            serialize_container(instance, xml, @fragments)
          end

          if @include_daos
            data.instances_with_digital_objects.each do |instance|
              serialize_digital_object(instance['digital_object']['_resolved'], xml, fragments)
            end
          end
        }

        # This is it. The patch. All one line of it for AOs
        serialize_aspace_content_warnings_ead3(data, xml, @fragments)
        # end the patch

        serialize_nondid_notes(data, xml, fragments)
        serialize_bibliographies(data, xml, fragments)
        serialize_indexes(data, xml, fragments)
        serialize_controlaccess(data, xml, fragments)
        EADSerializer.run_serialize_step(data, xml, fragments, :archdesc)

        data.children_indexes.each do |i|
          xml.text(
                   @stream_handler.buffer {|xml, new_fragments|
                     serialize_child(data.get_child(i), xml, new_fragments, c_depth + 1)
                   }
                   )
        end
      }
    rescue => e
      xml.text "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF ARCHIVAL OBJECTS. THE FOLLOWING INFORMATION MAY HELP:\n
                MESSAGE: #{e.message.inspect}  \n
                TRACE: #{e.backtrace.inspect} \n "
    end
  end

  # custom method to include Local Contexts data
  def serialize_aspace_content_warnings_ead3(data, xml, fragments)
    if AppConfig[:plugins].include?('aspace_content_warnings')
      if data.content_warnings && data.content_warnings.length > 0
        xml.odd {
          xml.head {
            sanitize_mixed_content(I18n.t("content_warning.section_title") , xml, fragments)
          }
          data.content_warnings.each do |cw|
            cw_type = cw['content_warning_code']
            if cw['description']
              cw_description = cw['description']
            else
              cw_description = I18n.t("content_warning_description.#{cw_type}")
            end
            cw_text = I18n.t("enumerations.content_warning_code.#{cw_type}") + ": " + cw_description
            xml.p {
              sanitize_mixed_content(cw_text , xml, fragments)
            }
          end
          }
      end
    end
  end

end
