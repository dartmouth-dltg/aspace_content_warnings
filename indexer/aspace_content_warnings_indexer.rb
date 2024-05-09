require 'aspace_logger'
class IndexerCommon

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('aspace_content_warnings')
      indexer.add_document_prepare_hook {|doc, record|
        record_data = record['record']
        doc['content_warnings_u_sstr'] = []
        doc['content_warnings_code_u_sstr'] = []
        doc['content_warnings_general_u_sbool'] = false
        if ['accession','resource', 'archival_object', 'digital_object', 'digital_object_component'].include?(doc['primary_type']) && record['record']['content_warnings']
          content_warnings = record_data['content_warnings']
          unless content_warnings.empty?
            doc['content_warnings_general_u_sbool'] = true
            content_warnings.each do |cw|
              doc['content_warnings_code_u_sstr'] << cw['content_warnings_code']
              doc['content_warnings_u_sstr'] << I18n.t('enumerations.content_warning_code.' + cw['content_warning_code'])
            end
          end
        end

        if ['archival_object', 'digital_object_component'].include?(doc['primary_type'])
          doc['inherited_content_warnings_u_sstr'] = []
          # only check if the object is not already tagged
          if doc['content_warnings_u_sstr'].empty?
            if record_data['ancestors'].nil?
              record_data = resolve_ancestors_for_pui(record)
            end
            get_content_warnings_data(record_data, doc)
          end
        end
      }
    end
  end

  def self.resolve_ancestors_for_pui(record)
    JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => ['ancestors, ancestors::content_warnings'])
  end

  def self.get_content_warnings_data(record, doc)
    tags = []
    inherit_level = nil
    inherit_uri = nil
    if record['ancestors'] && record['ancestors'].length > 0
      record['ancestors'].each do |anc|
        anc_data = anc['_resolved']
        next if anc_data['content_warnings'].nil?
        break if inherited_lcps.length > 0
        inherit_uri = anc_data['uri']
        if anc_data['jsonmodel_type'] == 'digital_object'
          inherit_level = 'digital object'
        elsif anc_data['jsonmodel_type'] == 'digital_object_component'
          inherit_level = 'digital object component'
        else 
          inherit_level = anc_data['level']
        end
        anc_data['content_warnings'].each do |cw|
          tags << I18n.t('enumerations.content_warning_code.' + cw['content_warning_code'])
        end
      end
      if tags.length > 0
        doc['inherited_content_warnings_u_sstr'] << {'tags' => tags, 'level' => inherit_level.capitalize, 'uri' => inherit_uri}.to_json
      end
    end
  end

end
