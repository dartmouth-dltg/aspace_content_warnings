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
          HarmfulContentEAD.serialize_aspace_content_warnings(data, xml, @fragments, EADSerializer)
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

        if AppConfig[:arks_enabled]
          ark_url = ArkName::get_ark_url(data.id, :archival_object)
          if ark_url
            xml.unitid {
              xml.extref ({"xlink:href" => ark_url,
                           "xlink:actuate" => "onload",
                           "xlink:show" => "new",
                           "xlink:type" => "simple"
                          }) { xml.text 'Archival Resource Key' }
            }
          end
        end

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
      HarmfulContentEAD.serialize_aspace_content_warnings(data, xml, @fragments, EADSerializer)
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

  # Override this method to include Harmful Content data
  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    return if digital_object["suppressed"] === true

    # ANW-285: Only serialize file versions that are published, unless include_unpublished flag is set
    file_versions_to_display = digital_object['file_versions'].select {|fv| fv['publish'] == true || @include_unpublished }

    title = digital_object['title']
    date = digital_object['dates'][0] || {}

    atts = {}

    content = ""
    content << title if title
    content << ": " if date['expression'] || date['begin']
    if date['expression']
      content << date['expression']
    elsif date['begin']
      content << date['begin']
      if date['end'] != date['begin']
        content << "-#{date['end']}"
      end
    end

    # Harmful Content start
    content << HarmfulContentEAD.serialize_aspace_content_warnings_for_digital_objects(digital_object)
    # Harmful Content end

    atts['xlink:title'] = digital_object['title'] if digital_object['title']


    if file_versions_to_display.empty?
      atts['xlink:type'] = 'simple'
      atts['xlink:href'] = digital_object['digital_object_id']
      atts['xlink:actuate'] = 'onRequest'
      atts['xlink:show'] = 'new'
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object)
      xml.dao(atts) {
        xml.daodesc { sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    elsif file_versions_to_display.length == 1
      file_version = file_versions_to_display.first

      atts['xlink:type'] = 'simple'
      atts['xlink:actuate'] = file_version['xlink_actuate_attribute'] || 'onRequest'
      atts['xlink:show'] = file_version['xlink_show_attribute'] || 'new'
      atts['xlink:role'] = file_version['use_statement'] if file_version['use_statement']
      atts['xlink:href'] = file_version['file_uri']
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object, file_version)
      xml.dao(atts) {
        xml.daodesc { sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    else
      atts['xlink:type'] = 'extended'
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object)
      xml.daogrp( atts ) {
        xml.daodesc { sanitize_mixed_content(content, xml, fragments, true) } if content
        file_versions_to_display.each do |file_version|
          atts = {}
          atts['xlink:type'] = 'locator'
          atts['xlink:href'] = file_version['file_uri']
          atts['xlink:role'] = file_version['use_statement'] if file_version['use_statement']
          atts['xlink:title'] = file_version['caption'] if file_version['caption']
          atts['audience'] = 'internal' unless is_digital_object_published?(digital_object, file_version)
          xml.daoloc(atts)
        end
      }
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

              # Change from EAD 2002: dao must be children of did in EAD3, not archdesc
              data.digital_objects.each do |dob|
                serialize_digital_object(dob, xml, @fragments)
              end

            }# </did>

            # This is it. The patch. All one line of it
            HarmfulContentEAD.serialize_aspace_content_warnings(data, xml, @fragments, EAD3Serializer)
            # end the patch

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

          if AppConfig[:arks_enabled]
            ark_url = ArkName::get_ark_url(data.id, :archival_object)
            if ark_url
              # <unitid><ref href=”ARK” show="new" actuate="onload">ARK</ref></unitid>
              xml.unitid {
                            xml.ref ({"href" => ark_url,
                                      "actuate" => "onload",
                                      "show" => "new"
                                      }) { xml.text 'Archival Resource Key' }
                          }
            end
          end

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
        HarmfulContentEAD.serialize_aspace_content_warnings(data, xml, @fragments, EAD3Serializer)
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

  # Override this method to include Harmful Content data
  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    return if digital_object["suppressed"] === true

    file_versions = digital_object['file_versions']
    title = digital_object['title']
    date = digital_object['dates'][0] || {}

    atts = {}

    content = ""
    content << title if title
    content << ": " if date['expression'] || date['begin']
    if date['expression']
      content << date['expression']
    elsif date['begin']
      content << date['begin']
      if date['end'] != date['begin']
        content << "-#{date['end']}"
      end
    end

    # Harmful Content start
    content << HarmfulContentEAD.serialize_aspace_content_warnings_for_digital_objects(digital_object)
    # Harmful Content end

    atts['linktitle'] = digital_object['title'] if digital_object['title']

    if digital_object['digital_object_type']
      atts['daotype'] = 'otherdaotype'
      atts['otherdaotype'] = digital_object['digital_object_type']
    else
      atts['daotype'] = 'unknown'
    end

    if file_versions.empty?
      atts['href'] = digital_object['digital_object_id']
      atts['actuate'] = 'onrequest'
      atts['show'] = 'new'
      atts['audience'] = 'internal' unless is_digital_object_published?(digital_object)
      xml.dao(atts) {
        xml.descriptivenote { sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    else
      file_versions.each do |file_version|
        atts['href'] = file_version['file_uri'] || digital_object['digital_object_id']
        atts['actuate'] = (file_version['xlink_actuate_attribute'].respond_to?(:downcase) && file_version['xlink_actuate_attribute'].downcase) || 'onrequest'
        atts['show'] = (file_version['xlink_show_attribute'].respond_to?(:downcase) && file_version['xlink_show_attribute'].downcase) || 'new'
        atts['localtype'] = file_version['use_statement'] if file_version['use_statement']
        atts['audience'] = 'internal' unless is_digital_object_published?(digital_object, file_version)
        xml.dao(atts) {
          xml.descriptivenote { sanitize_mixed_content(content, xml, fragments, true) } if content
        }
      end
    end
  end

end

class HarmfulContentEAD

  def self.serialize_aspace_content_warnings(data, xml, fragments, ead_serializer_class)
    if AppConfig[:plugins].include?('aspace_content_warnings')
      ead_serializer_caller = ead_serializer_class.new
      if data.content_warnings && data.content_warnings.length > 0
        xml.send(AppConfig[:aspace_content_warnings_note_type]) {
          xml.head {
            ead_serializer_caller.sanitize_mixed_content(I18n.t("content_warning.section_title") , xml, fragments)
          }
          if AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['general_only'] == true
            cw_text = general_cw_text
            xml.p {
              ead_serializer_caller.sanitize_mixed_content(cw_text , xml, fragments)
            }
          else
            data.content_warnings.each do |cw|
              xml.p {
                ead_serializer_caller.sanitize_mixed_content(assemble_content_warning_text(cw) , xml, fragments)
              }
            end
          end
          }
      end
    end
  end

  def self.serialize_aspace_content_warnings_for_digital_objects(digital_object)
    if AppConfig[:plugins].include?('aspace_content_warnings')
      if digital_object['content_warnings'] && digital_object['content_warnings'].length > 0
        content = "; "
        content << I18n.t("content_warning.section_title")
        content << ". "
        if AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['general_only'] == true
          content << general_cw_text
        else
          digital_object['content_warnings'].each_with_index do |cw, idx|
            content << assemble_content_warning_text(cw)
            unless idx == digital_object['content_warnings'].length - 1
              content << ", "
            end
          end
        end
      end
      content
    end
  end

  private

  def self.general_cw_text
    cw_text = I18n.t("enumerations.content_warning_code.cw_general") + " - " + I18n.t("content_warning_description.cw_general")
  end

  def self.assemble_content_warning_text(cw)
    cw_type = cw['content_warning_code']
    if cw['description']
      cw_description = cw['description']
    else
      cw_description = I18n.t("content_warning_description.#{cw_type}")
    end
    cw_text = I18n.t("enumerations.content_warning_code.#{cw_type}") + " - " + cw_description
  end

end
