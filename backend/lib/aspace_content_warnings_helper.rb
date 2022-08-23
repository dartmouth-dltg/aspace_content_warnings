class AspaceContentWarningsEADHelper

  def self.general_cw_text
    cw_text = I18n.t("enumerations.content_warning_code.cw_general") + " - " + I18n.t("content_warning_description.cw_general")
  end

  def self.assemble_content_warning_text(cw)
    cw_type = cw['content_warning_code']
    if cw['description']
      cw_description = cw['description']
    else
      cw_description = I18n.t("content_warning_description.#{cw_type}")
    end
    cw_text = I18n.t("enumerations.content_warning_code.#{cw_type}") + " - " + cw_description
  end

end