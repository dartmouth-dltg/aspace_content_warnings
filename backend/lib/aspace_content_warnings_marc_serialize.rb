class AspaceContentWarningsMARCSerialize

  DataField = Struct.new(:tag, :ind1, :ind2, :subfields)
  SubField = Struct.new(:code, :text)
  
  def initialize(record)
    @record = record
  end


  def datafields
    extra_fields = Array(@record.aspace_record && @record.aspace_record['content_warnings']).map do |cw|
      code = cw['content_warning_code'].to_s
      description = cw['description'].to_s.strip
      description = I18n.t("content_warning_description.#{code}_html", default: code) if description.empty?
      DataField.new('520', '4', ' ', [SubField.new('a', description)])
    end

    (@record.datafields + extra_fields).sort_by(&:tag)
  end

  def respond_to_missing?(name, include_private = false)
    @record.respond_to?(name, include_private) || super
  end

  def method_missing(name, *args, &block)
    @record.send(name, *args, &block)
  end

end
