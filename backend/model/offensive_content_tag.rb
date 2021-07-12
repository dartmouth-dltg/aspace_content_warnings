class OffensiveContentTag < Sequel::Model(:offensive_content_tag)
  include ASModel
  
  corresponds_to JSONModel(:offensive_content_tag)

  set_model_scope :global
  
end
