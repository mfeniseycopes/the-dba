require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.all

    results = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    SQL

    parse_all(results)
  end


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


  def self.last

    results = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    ORDER BY id DESC
    LIMIT
      1
    SQL

    results.empty? ? nil : self.new(results.first)
  end


  def self.parse_all(results)
    results.map { |row_hash| self.new(row_hash) }
  end


  def self.table_name
    if @table_name.nil?
      @table_name = self.to_s.tableize
    end

    @table_name
  end


  def self.table_name=(table_name = nil)
    @table_name = table_name
  end


  def initialize(params = {})
    unless params.empty?
      params.each do |attr_name, value|

        if class_obj.columns.include?(attr_name.to_sym)
          self.send("#{attr_name.to_s}=", params[attr_name])
        else
          # debugger
          raise "unknown attribute '#{attr_name}'"
        end

      end
    end
  end


  def attributes
    @attributes ||= {}
  end


  def attribute_values
    attributes.values
  end


  def insert

    DBConnection.execute2(<<-SQL, attribute_values)
      INSERT INTO
        #{class_obj.table_name} #{sql_columns}
      VALUES
        #{sql_question_marks}
    SQL

    self.id = DBConnection.last_insert_row_id
  end


  def class_obj
    self.class
  end


  def save
    id.nil? ? insert : update
  end


  def sql_columns
    "(#{attributes.keys.join(", ")})"
  end


  def sql_update_set
    attributes.keys.map { |attr_name| "#{attr_name} = ?" }
    .join(", ")
  end


  def sql_question_marks
    marks = ["?"] * attributes.length
    "(#{marks.join(", ")})"
  end


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

end
