require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

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
    @attributes = {}
    @columns.each do |column|
      columns.each do |column|
        # define getter
        define_method(column) do
          @attributes[column]
        end

        # define setter
        define_method("#{column}=") do |new_val|
          @attributes[column] = new_val
        end
      end
    end
  end

  def self.table_name=(table_name = nil)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      @table_name = self.to_s.tableize
    end

    @table_name
  end

  def self.all
    # ...
  end

  def self.parse_all(results)
    # ...
  end

  def self.find(id)
    # ...
  end

  def initialize(params = {})

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
  end

  def insert
    # ...
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
