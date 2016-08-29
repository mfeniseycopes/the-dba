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
