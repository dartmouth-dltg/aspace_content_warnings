class AspaceContentWarningsEADHelper

  def self.general_only?
    AppConfig.has_key?(:aspace_content_warnings) && AppConfig[:aspace_content_warnings]['general_only'] == true
  end

  def self.general_cw_text
    I18n.t("enumerations.content_warning_code.cw_general") + " - " + I18n.t("content_warning_description.cw_general_html")
  end

  def self.assemble_content_warning_text(cw)
    cw_type = cw['content_warning_code']
    cw_description = cw['description'].to_s.strip
    if cw_description.empty?
      cw_description = I18n.t("content_warning_description.#{cw_type}_html", default: cw_type.to_s)
    end
    I18n.t("enumerations.content_warning_code.#{cw_type}", default: cw_type.to_s) + " - " + cw_description
  end

end
