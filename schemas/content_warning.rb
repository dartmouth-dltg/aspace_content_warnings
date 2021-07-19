{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "offensive_content_tag_code" => {
        "type" => "string",
        "dynamic_enum" => "offensive_content_tag_code",
        "ifmissing" => "error"
      },
      "description" => {
        "type" => "string"
      }
    }
  }
}
