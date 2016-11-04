require_relative 'db_connection'

module Searchable

  # ensures that class extending the module implements parse_all
  def parse_all
    unless self.respond_to?(:parse_all)
      raise "Must implement parse_all(results) method in calling class"
    end
  end

  # creates criteria string
  def sql_criteria(column_names)
    res = column_names.map { |column| "#{column} = ?"}
      .join(" AND ")
  end

  # returns array of all instances st. all params are equal
  def where(params)
    results = DBConnection.execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{sql_criteria(params.keys)}
    SQL

    parse_all(results)
  end
end
