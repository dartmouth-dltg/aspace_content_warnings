module ContentWarnings

  def self.included(base)
    base.one_to_many :content_warning

    base.def_nested_record(:the_property => :content_warnings,
                           :contains_records_of_type => :content_warning,
                           :corresponding_to_association  => :content_warning,
                           :is_array => true)
  end

end
