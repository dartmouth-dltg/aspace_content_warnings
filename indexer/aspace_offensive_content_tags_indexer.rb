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
      }
    end
  end

end
