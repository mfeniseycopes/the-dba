require_relative 'searchable'
require 'active_support/inflector'

# base AssocOptions class
class AssocOptions

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  # create new AssocOptions instance with name and options
  def initialize(name, custom_options = {})
    # custom_options need not define all options
    options = defaults(name)
    options.merge!(custom_options) if custom_options.is_a?(Hash)

    options.each do |option, value|
      self.send("#{option}=", value)
    end
  end

  # provides access to the class attributes, methods
  def model_class
    class_name.constantize
  end

end

# creates belongs_to association options
class BelongsToOptions < AssocOptions

  def defaults(name)
    { class_name: name.to_s.camelcase,
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id }
  end

end

# creates has_many association options
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

# creates association instance methods
module Associatable

  # creates an instance method on the class by the same name as the provided association name, returns instance matching association
  def belongs_to(name, options = {})
    # association = BelongsToOptions.new(name, options)
    #
    # self.send(:define_method, name) do
    #   association.model_class.where(association.primary_key => self.send(association.foreign_key)).first
    # end
    #
    # self.assoc_options[name] = association

    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.foreign_key)
      options
        .model_class
        .where(options.primary_key => key_val)
        .first
    end
  end

  # creates an instance method on the class by the same name as the provided association name, returns instance of all matching associations
  def has_many(name, options = {})
    # association = HasManyOptions.new(name, self.to_s.singularize, options)
    #
    # self.send(:define_method, name) do
    #   association.model_class.where(association.foreign_key => self.send(association.primary_key))
    # end
    #
    # self.assoc_options[name] = association

    self.assoc_options[name] =
      HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.primary_key)
      options
        .model_class
        .where(options.foreign_key => key_val)
    end
  end

  # creates an instance method on the class by the same name as the provided association name, returns instance matching through association
  def has_one_through(name, through_name, source_name)

    self.send(:define_method, name) do
      self.send(through_name).send(source_name)
    end

  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    @assoc_options
  end

end
