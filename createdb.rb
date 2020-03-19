# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :courses do
  primary_key :id
  String :name
  String :city
  String :state
end
DB.create_table! :rounds do
  primary_key :id
  foreign_key :course_id
  foreign_key :round_id
  Integer :score
  String :tees
  Integer :date
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
courses_table = DB.from(:courses)

courses_table.insert(name: "The Legacy Golf Club", 
                    city: "Phoenix",
                    state: "AZ")

courses_table.insert(name: "Troon North Golf Club", 
                    city: "Scottsdale",
                    state: "AZ")
