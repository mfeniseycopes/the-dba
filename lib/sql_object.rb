require_relative 'db_connection'
require 'active_support/inflector'

require_relative 'associatable'
require_relative 'searchable'


class SQLObject

  extend Associatable
  extend Searchable

  # returns array of all records
  def self.all

    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  # sets list of all table columns on class, returns
  def self.columns
    if @columns.nil?
      # execute2 returns first row as column headers
      mini_table = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
        LIMIT 1
      SQL
      # sets class instance variable
      @columns = mini_table.first.map(&:to_sym)
    end
    @columns
  end

  # uses `define_method` to create attribute getter/setter methods for class instances
  def self.finalize!

    columns.each do |column|
      # define getter
      define_method(column) do
        attributes[column]
      end

      # define setter
      define_method("#{column}=") do |new_val|
        attributes[column] = new_val
      end
    end
  end

  # returns instance of record with matching id
  def self.find(id)
    # gets row w/ corresponding id
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    # returns nil if no results
    results.empty? ? nil : self.new(results.first)
  end

  # returns instance of first record
  def self.first

    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      LIMIT
        1
    SQL

    results.empty? ? nil : self.new(results.first)
  end

  # returns instance of last record
  def self.last

    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      ORDER BY 
        id DESC
      LIMIT
        1
    SQL

    results.empty? ? nil : self.new(results.first)
  end

  # creates an array of class instances from db query
  def self.parse_all(results)
    results.map { |row_hash| self.new(row_hash) }
  end

  # returns the table name
  def self.table_name
    if @table_name.nil?
      @table_name = self.to_s.tableize
    end

    @table_name
  end

  # sets the table name
  # this MUST be done before `finalze!` is called
  def self.table_name=(table_name = nil)
    @table_name = table_name
  end

  # initialize an instance with dynamic mass assignment
  def initialize(params = {})
    unless params.empty?
      params.each do |attr_name, value|

        if class_obj.columns.include?(attr_name.to_sym)
          self.send("#{attr_name.to_s}=", params[attr_name])
        else
          raise "unknown attribute '#{attr_name}'"
        end

      end
    end
  end

  # returns list of instance attribute names
  def attributes
    @attributes ||= {}
  end

  # returns list of instance attribute values
  def attribute_values
    attributes.values
  end

  # inserts new record into the table
  def insert

    DBConnection.execute2(<<-SQL, attribute_values)
      INSERT INTO
        #{class_obj.table_name} #{sql_columns}
      VALUES
        #{sql_question_marks}
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  # returns the instance's class
  def class_obj
    self.class
  end

  # upserts the record into the table
  def save
    id.nil? ? insert : update
  end

  # updates existing record in the table
  def update

    DBConnection.execute2(<<-SQL, attribute_values)
      UPDATE
        #{class_obj.table_name}
      SET
        #{sql_update_set}
      WHERE
        id = #{self.id}
    SQL

  end

  private
  # helper method to list all table columns in SQL statements
  def sql_columns
    "(#{attributes.keys.join(", ")})"
  end

  # helper method to list all row values in SQL statements
  def sql_update_set
    attributes.keys.map { |attr_name| "#{attr_name} = ?" }
      .join(", ")
  end

  # helper method to fill in '?' for SQL interpolation
  def sql_question_marks
    marks = ["?"] * attributes.length
    "(#{marks.join(", ")})"
  end
end
