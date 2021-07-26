{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "content_warning_code" => {
        "type" => "string",
        "dynamic_enum" => "content_warning_code",
        "ifmissing" => "error"
      },
      "description" => {
        "type" => "string"
      }
    }
  }
}
