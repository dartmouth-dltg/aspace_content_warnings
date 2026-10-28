class IndexerCommon

  CONTENT_WARNING_TYPES = ['accession', 'resource', 'archival_object', 'digital_object', 'digital_object_component'].freeze
  CONTENT_WARNING_CHILD_TYPES = ['archival_object', 'digital_object_component'].freeze

  # Inherited warnings need resolved ancestors. The PUI indexer only builds
  # documents for record inheritance types (by default just archival objects); for
  # other types (eg digital object components) the PUI shows the staff indexer's
  # document, so both indexers resolve ancestors, in the batch fetch rather than
  # with a GET per record.
  CONTENT_WARNINGS_RESOLVES = ['ancestors'].freeze
  CONTENT_WARNINGS_RESOLVES.each {|attr| add_attribute_to_resolve(attr)}

  # Inherited warnings are only needed in the document the PUI shows for a type
  def self.content_warnings_pui_document?(indexer, type)
    pui = defined?(PUIIndexer) && indexer.is_a?(PUIIndexer)
    inheritance_type = defined?(RecordInheritance) && RecordInheritance.has_type?(type)
    inheritance_type ? pui : !pui
  end

  # Core builds each staff document's json from the whole record, so with
  # ancestors resolved every archival object and component would store a full
  # copy of each ancestor. The hooks read ancestors from the record, so drop the
  # resolved copies from the json once they have all run. Other plugins that do
  # the same check the shared flag, so the json is only rewritten once. (The PUI
  # indexer removes ancestors from its own documents.)
  def self.content_warnings_strip_resolved_ancestors(doc, record)
    return if record['resolved_ancestors_stripped'] || doc['json'].nil?
    return unless Array(record['record']['ancestors']).any? {|anc| anc.is_a?(Hash) && anc['_resolved'] }

    json = ASUtils.json_parse(doc['json'])
    Array(json['ancestors']).each {|anc| anc.delete('_resolved') if anc.is_a?(Hash) }
    doc['json'] = ASUtils.to_json(json)
    record['resolved_ancestors_stripped'] = true
  end

  # final_doc_rules (archivesspace #3667) runs after all plugin hooks. Only add it
  # where core has it: the hook ordering below checks for it to detect older releases
  CONTENT_WARNINGS_CORE_FINAL_DOC_RULES = Object.private_method_defined?(:final_doc_rules) || method_defined?(:final_doc_rules)

  if CONTENT_WARNINGS_CORE_FINAL_DOC_RULES
    module ContentWarningsStripResolvedAncestors
      def final_doc_rules
        super
        unless defined?(PUIIndexer) && is_a?(PUIIndexer)
          add_document_prepare_hook {|doc, record| IndexerCommon.content_warnings_strip_resolved_ancestors(doc, record) }
        end
      end
    end
    prepend ContentWarningsStripResolvedAncestors
  end

  add_indexer_initialize_hook do |indexer|
    if AppConfig[:plugins].include?('aspace_content_warnings')
      # child types whose PUI document this indexer builds
      inherited_types = CONTENT_WARNING_CHILD_TYPES.select {|type| content_warnings_pui_document?(indexer, type) }

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

        next unless inherited_types.include?(doc['primary_type'])

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

      # older releases: strip after this plugin's hooks instead (see above)
      unless CONTENT_WARNINGS_CORE_FINAL_DOC_RULES || (defined?(PUIIndexer) && indexer.is_a?(PUIIndexer))
        indexer.add_document_prepare_hook {|doc, record| IndexerCommon.content_warnings_strip_resolved_ancestors(doc, record) }
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
      record_data = JSONModel::HTTP.get_json(record['uri'], 'resolve[]' => CONTENT_WARNINGS_RESOLVES)
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
