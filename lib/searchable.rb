require_relative 'db_connection'

module Searchable

  def parse_all
    unless self.response_to?(:parse_all)
      raise "Must implement parse_all(results) method in calling class"
    end
  end


  def sql_criteria(column_names)
    res = column_names.map { |column| "#{column} = ?"}
    .join(" AND ")
  end


  def where(params)
    #  debugger
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
