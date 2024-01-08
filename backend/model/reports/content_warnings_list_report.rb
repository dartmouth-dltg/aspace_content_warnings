class ContentWarningsListReport < AbstractReport

  register_report

  def fix_row(row)
    row[:Content_Warning_Default_Text] = I18n.t('content_warning_description.' + (row[:tag_code]  + '_html'), default: row[:tag_code])
    row[:create_time] = row[:create_time].strftime('%B %d, %Y')
  end

  def query_string
  "(
    SELECT
        content_warning.content_warning_code_id,
        content_warning.description,
        content_warning.create_time,
        resource.title AS title,
        'resource' AS type,
        enumeration_value.value AS tag_code
    FROM
        content_warning
    LEFT JOIN resource ON resource.id = content_warning.resource_id
    LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
    WHERE content_warning.resource_id IS NOT null
    ORDER BY
        title,
        tag_code
  )
  UNION
      (
      SELECT
          content_warning.content_warning_code_id,
          content_warning.description,
          content_warning.create_time,
          accession.title AS title,
          'accession' AS type,
          enumeration_value.value AS tag_code
      FROM
          content_warning
      LEFT JOIN accession ON accession.id = content_warning.accession_id
      LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
      WHERE content_warning.accession_id IS NOT null
      ORDER BY
          title,
          tag_code
  )
  UNION
      (
      SELECT
          content_warning.content_warning_code_id,
          content_warning.description,
          content_warning.create_time,
          archival_object.title AS title,
          'archival object' AS type,
          enumeration_value.value AS tag_code
      FROM
          content_warning
      LEFT JOIN archival_object ON archival_object.id = content_warning.archival_object_id
      LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
      WHERE content_warning.archival_object_id IS NOT null
      ORDER BY
          title,
          tag_code
  )
  UNION
      (
      SELECT
          content_warning.content_warning_code_id,
          content_warning.description,
          content_warning.create_time,
          digital_object.title AS title,
          'digital object' AS type,
          enumeration_value.value AS tag_code
      FROM
          content_warning
      LEFT JOIN digital_object ON digital_object.id = content_warning.digital_object_id
      LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
      WHERE content_warning.digital_object_id IS NOT null
      ORDER BY
          title,
          tag_code
  )
  UNION
      (
      SELECT
          content_warning.content_warning_code_id,
          content_warning.description,
          content_warning.create_time,
          digital_object_component.title AS title,
          'digital object component' AS type,
          enumeration_value.value AS tag_code
      FROM
          content_warning
      LEFT JOIN digital_object_component ON digital_object_component.id = content_warning.digital_object_component_id
      LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
      WHERE content_warning.digital_object_component_id IS NOT null
      ORDER BY
          title,
          tag_code
  )
  "
  end

end
