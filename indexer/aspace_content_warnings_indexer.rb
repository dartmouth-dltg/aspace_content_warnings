class IndexerCommon

  CONTENT_WARNING_TYPES = ['accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'].freeze
  CONTENT_WARNING_CHILD_TYPES = ['archival_object', 'digital_object_component'].freeze

  # Only the PUI shows inherited warnings, so only the PUI indexer needs resolved
  # ancestors. add_attribute_to_resolve applies to every indexer, which made the
  # staff indexer fetch the full JSON of every ancestor of every archival object.
  # The PUI indexer already resolves 'ancestors' for record inheritance
  # (AppConfig[:record_inheritance_resolves]); make sure it stays there. PUIIndexer
  # reads this when it loads, which is after the plugin indexers.
  CONTENT_WARNINGS_PUI_RESOLVES = ['ancestors'].freeze
  AppConfig[:record_inheritance_resolves] = (Array(AppConfig[:record_inheritance_resolves]) + CONTENT_WARNINGS_PUI_RESOLVES).uniq

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('aspace_content_warnings')
      # only the PUI shows inherited warnings, and only it resolves ancestors
      pui = defined?(PUIIndexer) && indexer.is_a?(PUIIndexer)

      hook = proc {|doc, record|
        doc['content_warnings_u_sstr'] = []
        doc['content_warnings_code_u_sstr'] = []
        doc['content_warnings_general_u_sbool'] = false
        next unless CONTENT_WARNING_TYPES.include?(doc['primary_type'])

        content_warnings = Array(record['record']['content_warnings'])
        unless content_warnings.empty?
          doc['content_warnings_general_u_sbool'] = true
          content_warnings.each do |cw|
            doc['content_warnings_code_u_sstr'] << cw['content_warning_code']
            doc['content_warnings_u_sstr'] << content_warning_label(cw['content_warning_code'])
          end
        end

        next unless pui && CONTENT_WARNING_CHILD_TYPES.include?(doc['primary_type'])

        doc['inherited_content_warnings_u_sstr'] = []
        # only check if the object is not already tagged
        next unless content_warnings.empty?

        ancestors = content_warnings_resolved_ancestors(record)
        ancestor = ancestors.find {|anc| anc['_resolved'] && !Array(anc['_resolved']['content_warnings']).empty?}
        doc['inherited_content_warnings_u_sstr'] << ancestor_content_warnings(ancestor['_resolved']) if ancestor
      }

      # PUIIndexer's own prepare hook deletes record['record']['ancestors']. Before
      # final_doc_rules (archivesspace #3667) it ran ahead of plugin hooks, so go
      # first there or every AO costs a backend GET
      if indexer.respond_to?(:final_doc_rules, true)
        indexer.add_document_prepare_hook(&hook)
      else
        indexer.instance_variable_get(:@document_prepare_hooks).unshift(hook)
      end
    end
  end

  def self.content_warning_label(code)
    I18n.t("enumerations.content_warning_code.#{code}", default: code)
  end

  # fall back to fetching the record if ancestors somehow arrived unresolved
  def self.content_warnings_resolved_ancestors(record)
    ancestors = record['record']['ancestors']
    if ancestors.nil? || ancestors.any? {|anc| anc['_resolved'].nil?}
      record_data = JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => CONTENT_WARNINGS_PUI_RESOLVES)
      ancestors = record_data && record_data['ancestors']
    end
    Array(ancestors)
  end

  def self.ancestor_content_warnings(anc)
    level = case anc['jsonmodel_type']
            when 'digital_object' then 'digital object'
            when 'digital_object_component' then 'digital object component'
            else anc['level'].to_s
            end

    tags = anc['content_warnings'].map {|cw| content_warning_label(cw['content_warning_code'])}
    {'tags' => tags, 'level' => level.capitalize, 'uri' => anc['uri']}.to_json
  end

end
