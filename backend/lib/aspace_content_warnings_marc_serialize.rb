require 'aspace_logger'

class AspaceContentWarningsMARCSerialize

  DataField = Struct.new(:tag, :ind1, :ind2, :subfields)
  SubField = Struct.new(:code, :text)
  
  def initialize(record)
    @record = record
  end


  def datafields
    extra_fields = []
    
    if @record.aspace_record['content_warnings']
      @record.aspace_record['content_warnings'].each do |cw|
        if cw['description'].nil?
          cw_description = I18n.t('content_warning_description.' + cw['content_warning_code'], default: cw['content_warning_code'].nil? ? '' : cw['content_warning_code'])
        else
          cw_description = cw['description']
        end
        extra_fields << DataField.new('520', '4', ' ', [SubField.new('a', cw_description)])
      end
    end

    (@record.datafields + extra_fields).sort_by(&:tag)
  end

  def method_missing(*args)
    @record.send(*args)
  end
  
  end