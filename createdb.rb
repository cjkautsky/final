# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :courses do
  primary_key :id
  String :lat_lng, text: true 
  String :name, text: true
  String :city
  String :state
end
DB.create_table! :rounds do
  primary_key :id
  foreign_key :course_id
  foreign_key :user_id
  Integer :score
  String :tees
  String :date
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
courses_table = DB.from(:courses)

courses_table.insert(lat_lng: "33.5021365,-82.0248163",
                    name: "Augusta National", 
                    city: "Augusta",
                    state: "GA")

courses_table.insert(lat_lng: "36.5696553,-121.9519442",
                    name: "Pebble Beach", 
                    city: "Pebble Beach",
                    state: "CA")
