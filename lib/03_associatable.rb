require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions

  def initialize(name, custom_options = {})
    options = defaults(name)
    options.merge!(custom_options) if custom_options.is_a?(Hash)

    options.each do |option, value|
      self.send("#{option}=", value)
    end
  end

  attr_accessor(
  :foreign_key,
  :class_name,
  :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    begin
      model_class.table_name
    rescue NoMethodError => e
      raise "#{model_class} must implement 'table_name' method definition"
    end
  end

end

class BelongsToOptions < AssocOptions

  def defaults(name)
    { class_name: name.camelcase,
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id }
  end

end

class HasManyOptions < AssocOptions

  def initialize(name, klass, custom_options = {})
    options = defaults(name, klass)
    options.merge!(custom_options) if custom_options.is_a?(Hash)

    options.each do |option, value|
      self.send("#{option}=", value)
    end
  end

  def defaults(name, klass)
    { class_name: name.camelcase,
      foreign_key: "#{klass.downcase}_id".to_sym,
      primary_key: :id }
  end
end

module Associatable
  # Phase IIIb

  def belongs_to(name, options = {})
    association = BelongsToOptions.new(name, options)
    owner = association.model_class
            .send(association.foreign_key)
            .where(association.primary_key = self.id)
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  include Associatable
end
