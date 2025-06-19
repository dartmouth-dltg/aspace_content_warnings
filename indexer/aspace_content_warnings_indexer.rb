require 'aspace_logger'
class IndexerCommon

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('aspace_content_warnings')
      indexer.add_document_prepare_hook {|doc, record|
        doc['content_warnings_u_sstr'] = []
        doc['content_warnings_code_u_sstr'] = []
        doc['content_warnings_general_u_sbool'] = false
        if ['accession','resource', 'archival_object', 'digital_object', 'digital_object_component'].include?(doc['primary_type']) && record['record']['content_warnings']
          content_warnings = record['record']['content_warnings']
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
            record_data = check_ancestors_are_resolved(record)

            record_data['ancestors'].each do |ancestor|
              if ancestor['_resolved'] && ancestor['_resolved']['content_warnings']
                anc_cw = get_ancestor_content_warnings(ancestor['_resolved'], doc)
                doc['inherited_content_warnings_u_sstr'] << anc_cw unless anc_cw.nil?
                break if doc['inherited_content_warnings_u_sstr'].length > 0
              end
            end
          end
        end
      }
    end
  end

  # do we really need to be this paranoid?
  def self.check_ancestors_are_resolved(record)
    record_data = record['record']

    if record_data['ancestors'].nil?
      record_data = resolve_ancestors(record)
    else
      record_data['ancestors'].each do |anc|
        if anc['_resolved'].nil?
          record_data = resolve_ancestors(record)
          break
        end
      end
    end

    return record_data

  end

  def self.resolve_ancestors(record)
    JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => ['ancestors', 'ancestors::content_warnings'])
  end

  def self.get_ancestor_content_warnings(anc, doc)
    tags = []
    level = anc['level']

    if anc['jsonmodel_type'] == 'digital_object'
      level = 'digital object'
    elsif anc['jsonmodel_type'] == 'digital_object_component'
      level = 'digital object component'
    end

    anc['content_warnings'].each do |cw|
      tags << I18n.t('enumerations.content_warning_code.' + cw['content_warning_code'])
    end

    if tags.length > 0
      {'tags' => tags, 'level' => level.capitalize, 'uri' => parent['uri']}.to_json
    else
      nil
    end
  end

end
