class ContentWarning < Sequel::Model(:content_warning)
  include ASModel
  
  corresponds_to JSONModel(:content_warning)

  set_model_scope :global
  
end
