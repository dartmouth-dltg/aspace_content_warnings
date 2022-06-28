require 'aspace_logger'
class IndexerCommon

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('aspace_content_warnings')
      indexer.add_document_prepare_hook {|doc, record|
        if ['accession','resource', 'archival_object', 'digital_object', 'digital_object_component'].include?(doc['primary_type']) && record['record']['content_warnings']
          content_warnings = record['record']['content_warnings']
          doc['content_warnings_u_sstr'] = []
          doc['content_warnings_code_u_sstr'] = []
          doc['content_warnings_general_u_sbool'] = true
          content_warnings.each do |cw|
            doc['content_warnings_code_u_sstr'] << cw['content_warnings_code']
            doc['content_warnings_u_sstr'] << I18n.t('enumerations.content_warning_code.' + cw['content_warning_code'])
          end
        end

        if ['archival_object', 'digital_object_component'].include?(doc['primary_type'])
          doc['inherited_content_warnings_u_sstr'] = []
          # only check if the object is not already tagged
          if doc['content_warnings_u_sstr'].empty?
            if record['record']['parent']
              get_parent_content_warnings(record['record']['parent']['ref'], doc)
            elsif record['record']['resource']
              get_parent_content_warnings(record['record']['resource']['ref'], doc)
            elsif record['record']['digital_object']
              get_parent_content_warnings(record['record']['digital_object']['ref'], doc)
            end
          end
        end
      }
    end
  end

  def self.get_parent_content_warnings(uri, doc)
    tags = []
    parent = JSONModel::HTTP.get_json(uri)
    level = parent['level']
    if parent['jsonmodel_type'] == 'digital_object'
      level = 'digital object'
    elsif parent['jsonmodel_type'] == 'digital_object_component'
      level = 'digital object component'
    end
    parent['content_warnings'].each do |cw|
      tags << I18n.t('enumerations.content_warning_code.' + cw['content_warning_code'])
    end
    if tags.length > 0
      doc['inherited_content_warnings_u_sstr'] << {'tags' => tags, 'level' => level.capitalize, 'uri' => parent['uri']}.to_json
    end
    if doc['inherited_content_warnings_u_sstr'].empty?
      if parent['parent']
        get_parent_content_warnings(parent['parent']['ref'], doc)
      elsif parent['resource']
        get_parent_content_warnings(parent['resource']['ref'], doc)
      elsif parent['digital_object']
        get_parent_content_warnings(parent['digital_object']['ref'], doc)
      end
    end
  end

end
