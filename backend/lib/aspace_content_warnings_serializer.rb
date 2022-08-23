require 'aspace_logger'

class EADAspaceContentWarningsSerialize < EADSerializer

  def call(data, xml, fragments, context)
    acw_ead = AspaceContentWarningsEAD.new

    if context == :archdesc
      acw_ead.serialize_aspace_content_warnings(data, xml, fragments)
    end

    if context == :dao
      acw_ead.serialize_aspace_content_warnings_for_digital_objects(data, xml, fragments)
    end
  end

end

class EAD3AspaceContentWarningsSerialize < EAD3Serializer

  def call(data, xml, fragments, context)
    acw_ead3 = AspaceContentWarningsEAD3.new

    if context == :archdesc
      acw_ead3.serialize_aspace_content_warnings(data, xml, fragments)
    end

    if context == :dao
      acw_ead3.serialize_aspace_content_warnings_for_digital_objects(data, xml, fragments)
    end
  end

end