class OffensiveContentTagsListReport < AbstractReport

  register_report

  def query_string
  "(
    SELECT
      offensive_content_tag.offensive_content_tag_code_id,
      resource.title as title,
      'resource' AS type,
      enumeration_value.value as tag_code
    FROM
      resource
    LEFT JOIN
      offensive_content_tag ON resource.id = offensive_content_tag.resource_id
    LEFT JOIN
      enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
    ORDER BY
      title,
      tag_code
  )
  UNION
  (
    SELECT
      offensive_content_tag.offensive_content_tag_code_id,
      accession.title as title,
      'accession' AS type,
      enumeration_value.value as tag_code
    FROM
      accession
    LEFT JOIN
      offensive_content_tag ON accession.id = offensive_content_tag.resource_id
    LEFT JOIN
      enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
    ORDER BY
      title,
      tag_code
  )
  UNION
  (
    SELECT
      offensive_content_tag.offensive_content_tag_code_id,
      archival_object.title as title,
      'archival object' AS type,
      enumeration_value.value as tag_code
    FROM
      archival_object
    LEFT JOIN
      offensive_content_tag ON archival_object.id = offensive_content_tag.resource_id
    LEFT JOIN
      enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
    ORDER BY
      title,
      tag_code
  )
  UNION
  (
    SELECT
      offensive_content_tag.offensive_content_tag_code_id,
      digital_object.title as title,
      'digital object' AS type,
      enumeration_value.value as tag_code
    FROM
      resource
    LEFT JOIN
      offensive_content_tag ON digital_object.id = offensive_content_tag.resource_id
    LEFT JOIN
      enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
    ORDER BY
      title,
      tag_code
  )
  "
  end

end
