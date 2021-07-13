require 'aspace_logger'
class IndexerCommon

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('aspace_offensive_content_tags')
      indexer.add_document_prepare_hook {|doc, record|
        if ['accession','resource', 'archival_object', 'digital_object'].include?(doc['primary_type']) && record['record']['offensive_content_tags']
          offensive_content_tags = record['record']['offensive_content_tags']
          doc['offensive_content_tags_u_sstr'] = []
          doc['offensive_content_tags_code_u_sstr'] = []
          offensive_content_tags.each do |oct|
            doc['offensive_content_tags_code_u_sstr'] << oct['offensive_content_tags_code']
            doc['offensive_content_tags_u_sstr'] << I18n.t('enumerations.offensive_content_tag_code.' + oct['offensive_content_tag_code'])
          end
        end
        
        if doc['primary_type'] == 'archival_object'
          doc['inherited_offensive_content_tags_u_sstr'] = []
          # only check if the object is not already tagged
          if doc['offensive_content_tags_u_sstr'].empty?
            if record['record']['parent']
              get_parent_offensive_tags(record['record']['parent']['ref'], doc)
            elsif record['record']['resource']
              get_parent_offensive_tags(record['record']['resource']['ref'], doc)
            end
          end
        end
      }
    end
  end
  
  def self.get_parent_offensive_tags(uri, doc)
    tags = []
    parent = JSONModel::HTTP.get_json(uri)
    parent['offensive_content_tags'].each do |oct|
      tags << I18n.t('enumerations.offensive_content_tag_code.' + oct['offensive_content_tag_code'])
    end
    if tags.length > 0
      doc['inherited_offensive_content_tags_u_sstr'] << {'tags' => tags, 'level' => parent['level'], 'uri' => parent['uri']}.to_json
    end
    if doc['inherited_offensive_content_tags_u_sstr'].empty?
      if parent['parent']
        get_parent_offensive_tags(parent['parent']['ref'], doc)
      elsif parent['resource']
        get_parent_offensive_tags(parent['resource']['ref'], doc)
      end
    end
  end

end
