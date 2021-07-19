class ContentWarningsListReport < AbstractReport

  register_report
  
  # we override this since the query may return too many results
  def get_content
    array = []
    query.each do |result|
      row = result.to_hash
      next if row[:content_warning_code_id].nil?
      fix_row(row)
      array.push(row)
    end
    info[:repository] = repository
    after_tasks
    array
  end

  def query_string
  "(
    SELECT
        content_warning.content_warning_code_id,
        content_warning.description,
        resource.title AS title,
        'resource' AS type,
        enumeration_value.value AS tag_code
    FROM
        resource
    LEFT JOIN content_warning ON resource.id = content_warning.resource_id
    LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
    ORDER BY
        title,
        tag_code
  )
  UNION
      (
      SELECT
          content_warning.content_warning_code_id,
          content_warning.description,
          accession.title AS title,
          'accession' AS type,
          enumeration_value.value AS tag_code
      FROM
          accession
      LEFT JOIN content_warning ON accession.id = content_warning.resource_id
      LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
      ORDER BY
          title,
          tag_code
  )
  UNION
      (
      SELECT
          content_warning.content_warning_code_id,
          content_warning.description,
          archival_object.title AS title,
          'archival object' AS type,
          enumeration_value.value AS tag_code
      FROM
          archival_object
      LEFT JOIN content_warning ON archival_object.id = content_warning.resource_id
      LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
      ORDER BY
          title,
          tag_code
  )
  UNION
      (
      SELECT
          content_warning.content_warning_code_id,
          content_warning.description,
          digital_object.title AS title,
          'digital object' AS type,
          enumeration_value.value AS tag_code
      FROM
          digital_object
      LEFT JOIN content_warning ON digital_object.id = content_warning.resource_id
      LEFT JOIN enumeration_value ON enumeration_value.id = content_warning.content_warning_code_id
      ORDER BY
          title,
          tag_code
  )
  "
  end

end
