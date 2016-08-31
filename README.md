# the-dba

the-dba is an ORM (Object Relation Mapping Tool) that is intended to abstract away the database implementation (namely SQL).

the-dba uses SQL queries tucked nicely away into class methods to provide typical SQL statement functionality. Creating a class which extends the SQLObject class provides an abstract 'table' to apply associations and perform CRUD on.

`the-dba` is inspired by RoR's ActiveRecord.

## How to Use

### An Example 
The following code walks you through using the-dba with the provided sample database. See ['Running the-dba'](#running) for complete steps to use with your own database.

```ruby
require_relative "lib/sql_object"

class Stembolt < SQLObject
  table_name = "stembolts"
  finalize!

  belongs_to :officer
  has_one_through :ship, :officer, :ship
end

class Officer < SQLObject
  table_name = "officers"
  finalize!

  belongs_to :ship
  has_many :stembolts
end

class Ship < SQLObject
  table_name = "ships"
  finalize!

  has_many :officers
end

Stembolt.all
# => [#<Stembolt:0x0055d09707ab80
#     @attributes={:id=>1, :color=>"Blue", :officer_id=>1}>,
#  #<Stembolt:0x0055d09707a978
#     @attributes={:id=>2, :color=>"Green", :officer_id=>2}>,
#  #<Stembolt:0x0055d09707a838
#     @attributes={:id=>3, :color=>"Grey", :officer_id=>2}>,
#  #<Stembolt:0x0055d09707a568
#     @attributes={:id=>4, :color=>"Yellow", :officer_id=>2}>]

Officer.first
# => #<Officer:0x0055d096ccbc50
# @attributes={:id=>1, :name=>"Geordi Laforge", :ship_id=>1}>

Officer.first.ship
# => #<Ship:0x0055d0977ba648 @attributes={:id=>1, :name=>"Enterprise"}>

# find a ship
enterprise = Ship.where(name: "Enterprise").first

# create new officer instance
spock = Officer.new(name: "Spock", ship_id: enterprise.id)

# insert into db
spock.insert

# change attribute
spock.name = "Mr. Spock"

# update db record
spock.save
```

### Running the-dba<a name="running"></a>

Including the-dba is as easy (well almost) as extending the SQLObject class.

Prerequisites: MySQL, Ruby and `bundler` gem installed

1. Clone the repo into your working directory.
  - `$ git clone http://github.com/mfeniseycopes/the-dba.git`
2. Install dependencies. 

```
  $ cd the-dba
  $ bundle install
```
3. Setup db connection.
  - The simplest way to do this is to import your own `*.db` & `*.sql` files and rename them `stembolts.db` & `stembolts.sql`.
  - Otherwise you will need to change the references to `stembolts.db` & `stembolts.sql` to whatever filenames you are using.
4. Create a new class by extending `SQLObject`.
5. Make sure to set the table name within your new class before initializing any instances.
  - `self.table_name = "<your db table name>"`
6. Build associations. Assuming you don't have a single table, so try adding some associations between your foreign and primary keys.
7. Play!

*See example below or try running the code in `demo.rb`*


## SQLObject

To create a working SQLObject class it is necessary to extend the `SQLObject` class and set the table_name. `SQLObject` queries the database to gather the column names dynamically from the column headers in a query result.

```ruby
class Stembolt < SQLObject
  self.table_name = "stembolts"
  finalize!
end
# that's it!
```

Columns names retrieved via db query utilizing table headers as default table names:
```ruby
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
```

Inheriting from `SQLObject` class provides handy getter/setter methods for each column. These are added to the class by implementing `define_method` with the dynamically retrieved table names:

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
* `::has_one_through` - takes an association name and an options hash detailing the association providing the through association and the name of that through association.


