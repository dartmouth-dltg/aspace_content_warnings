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
      
        # for archival objects, check up the ancestor tree to see if any ancestors have applied any offensive content tags
        if doc['primary_type'] == 'archival_object' && record['record']['offensive_content_tags'].empty?
          doc['ancestor_applied_offensive_tags_u_sstr'] = []
          doc['ancestor_applied_offensive_tags_at_level_u_sstr'] = ''
          doc['ancestor_applied_offensive_tags_uri_u_sstr'] = ''
          if record['record']['ancestors']
            record['record']['ancestors'].each do |anc|
              if doc['ancestor_applied_offensive_tags_at_level_u_sstr'].empty?
                res_anc = JSONModel::HTTP.get_json(anc['ref'])
                next if res_anc['offensive_content_tags'].empty?
                res_anc['offensive_content_tags'].each do |oct|
                  doc['ancestor_applied_offensive_tags_u_sstr'] << I18n.t('enumerations.offensive_content_tag_code.' + oct['offensive_content_tag_code'])
                end
                doc['ancestor_applied_offensive_tags_at_level_u_sstr'] = res_anc['level']
                doc['ancestor_applied_offensive_tags_uri_u_sstr'] = res_anc['uri']
              end
            end
          end
          
        end
      }
    end
  end

end
