require_relative 'searchable'
require 'active_support/inflector'

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
    { class_name: name.to_s.camelcase,
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
    { class_name: name.to_s.camelcase.singularize,
      foreign_key: "#{klass.downcase}_id".to_sym,
      primary_key: :id }
  end
end

module Associatable
  
  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end

  def belongs_to(name, options = {})
    association = BelongsToOptions.new(name, options)

    self.send(:define_method, name) do
      association.model_class.where(association.primary_key => self.send(association.foreign_key)).first
    end

    self.assoc_options[name] = association
  end

  def has_many(name, options = {})
    association = HasManyOptions.new(name, self.to_s.singularize, options)

    self.send(:define_method, name) do
      association.model_class.where(association.foreign_key => self.send(association.primary_key))
    end

    self.assoc_options[name] = association
  end

  def has_one_through(name, through_name, source_name)

    self.send(:define_method, name) do
      thru_association = self.class.assoc_options[through_name]

      self.send(through_name).send(source_name)
    end

  end

end


class SQLObject
  extend Associatable
end
