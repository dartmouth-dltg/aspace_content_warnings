module OffensiveContentTags

  def self.included(base)
    base.one_to_many :offensive_content_tag

    base.def_nested_record(:the_property => :offensive_content_tags,
                           :contains_records_of_type => :offensive_content_tag,
                           :corresponding_to_association  => :offensive_content_tag,
                           :is_array => true)
  end

end
