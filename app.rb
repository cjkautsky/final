# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

users_table = DB.from(:users)
courses_table = DB.from(:courses)
rounds_table = DB.from(:rounds)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and leaderboard
get "/" do
    view "leaderboard"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# display the round entry form (aka "new")
get "/rounds/new_round" do
    view "new_round"
end

# receive the submitted round form (aka "create")
post "/rounds/create_round" do
    puts "params: #{params}"
    @course_played = courses_table.where(name: params["course"]).to_a[0]


    if @course_played 
        if !!(params["date"] =~ /^\d{1,2}\-\d{1,2}\-\d{4,4}$/) || !!(params["date"] =~ /^\d{1,2}\/\d{1,2}\/\d{4,4}$/)
            @users_table = users_table
            rounds_table.insert(
                user_id: session["user_id"],
                course_id: @course_played[:id],
                score: params["score"],
                tees: params["tees"],
                date: params["date"],
            )
            view "create_round"
        else
            view "create_round_failed"
        end
    else
        view "create_round_failed"
    end
end

# display the course entry form (aka "new")
get "/courses/new_course" do
    view "new_course"
end

# receive the submitted course form (aka "create")
post "/courses/create_course" do
    view "create_course"
end

# display the leaderboard by the desired filter (by course, city, or month)
get "/rounds/filtered_leaderboard" do
    view "filtered_leaderboard"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "login_error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )
        view "create_user"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]
    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    view "logout"
end