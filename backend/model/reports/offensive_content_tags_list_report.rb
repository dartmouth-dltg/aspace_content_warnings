class OffensiveContentTagsListReport < AbstractReport

  register_report
  
  # we override this since the query may return too many results
  def get_content
    array = []
    query.each do |result|
      row = result.to_hash
      next if row[:offensive_content_tag_code_id].nil?
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
        offensive_content_tag.offensive_content_tag_code_id,
        offensive_content_tag.description,
        resource.title AS title,
        'resource' AS type,
        enumeration_value.value AS tag_code
    FROM
        resource
    LEFT JOIN offensive_content_tag ON resource.id = offensive_content_tag.resource_id
    LEFT JOIN enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
    ORDER BY
        title,
        tag_code
  )
  UNION
      (
      SELECT
          offensive_content_tag.offensive_content_tag_code_id,
          offensive_content_tag.description,
          accession.title AS title,
          'accession' AS type,
          enumeration_value.value AS tag_code
      FROM
          accession
      LEFT JOIN offensive_content_tag ON accession.id = offensive_content_tag.resource_id
      LEFT JOIN enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
      ORDER BY
          title,
          tag_code
  )
  UNION
      (
      SELECT
          offensive_content_tag.offensive_content_tag_code_id,
          offensive_content_tag.description,
          archival_object.title AS title,
          'archival object' AS type,
          enumeration_value.value AS tag_code
      FROM
          archival_object
      LEFT JOIN offensive_content_tag ON archival_object.id = offensive_content_tag.resource_id
      LEFT JOIN enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
      ORDER BY
          title,
          tag_code
  )
  UNION
      (
      SELECT
          offensive_content_tag.offensive_content_tag_code_id,
          offensive_content_tag.description,
          digital_object.title AS title,
          'digital object' AS type,
          enumeration_value.value AS tag_code
      FROM
          digital_object
      LEFT JOIN offensive_content_tag ON digital_object.id = offensive_content_tag.resource_id
      LEFT JOIN enumeration_value ON enumeration_value.id = offensive_content_tag.offensive_content_tag_code_id
      ORDER BY
          title,
          tag_code
  )
  "
  end

end
