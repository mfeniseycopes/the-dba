# the-dba

the-dba is an ORM (Object Relation Mapping Tool) that is intended to abstract away the database implementation (namely SQL).

the-dba uses SQL queries tucked nicely away into class methods to provide typical SQL statement functionality. Creating a class which extends the SQLObject class provides an abstract 'table' which to apply associations and perform CRUD on.

`the-dba` is inspired by RoR's ActiveRecord.

## SQLObject

To create a working SQLObject class it is necessary to extend the `SQLObject` class and set the table_name. `SQLObject` queries the database to gather the column names dynamically from the column headers in a query result.

```ruby
class Stembolt < SQLObject
  self.table_name = "stembolts"
end
# that's it!
```

Column names are made available as getter/setter methods by using `define_method`:

```ruby
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
```

Instances of SQLObject can be initialized with mass assignment via `Object#send` method:

```ruby
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
```


From here we have access to the following `the-dba` methods:

* `::new` - takes a params hash for mass variable assignment
* `::all` - returns an array of all records in the table
* `::find` - returns the record with a matching id
* `::first` - returns the first record in the table
* `::last` - returns the last record in the table
* `#insert` - saves a non-persisted instance to the db
* `#update` - updates the associated record in the db
* `#save` - combines `insert` and `update` (works on persisted and non-persisted instances)

## Searchable

By extending the `Searchable` module into the SQLObject class we add even more advanced querying functionality. All without looking at a single ALLCAPS word. Yay!

Additional methods:

* `::where` - takes hash of key/value pairs such that key is a table column name and value is the record value. Returns array of SQLObject instances.

## Associatable

More? Yes! The `Associatable` module provides some basic associations. Just like ActiveRecord, `Associatable` methods provide some very convenient defaults if you stick to the naming conventions. Each method creates an instance method on the class by the same name as the provided association name, which returns instances of all matching associations.

Additional methods:

* `::belongs_to` - takes an association name and an optional options hash detailing the primary_key, foreign_key and class name which the relationship is applied.
* `::has_many` - takes an association name and an optional options hash detailing the primary_key, foreign_key and class name which the relationship is applied.
* `::has_one_through` - takes an association name and an optional options hash detailing the primary_key, foreign_key and class name which the relationship is applied.
