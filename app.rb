# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"
require "geocoder"                                                                      #
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
    @courses_table = courses_table
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
    @course_played = courses_table.where(Sequel.like(:name, "%#{params["course"]}%")).to_a[0]

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

# receive the submitted course form and check it is correct (aka "check")
post "/courses/course_check" do
    results = Geocoder.search(params["course"])
    @lat_lng = results.first.coordinates
    @lat = @lat_lng[0]
    @long = @lat_lng[1]
    @course_check = "#{@lat},#{@long}"
    puts @lat
    puts @long
    view "course_check"
end

# receive the submitted course form and add to database (aka "create")
post "/courses/create_course" do
    puts "params: #{params}"
    results = Geocoder.search(params[:course])
    course_city = results.first.city
    course_state = results.first.state
    course_name = results.first.address

    existing_course = courses_table.where(lat_lng: params["course"]).to_a[0]
    if existing_course
       view "create_course_failed" 
    else    
        courses_table.insert(
            lat_lng: params["course"],
            name: course_name,
            city: course_city,
            state: course_state,
        )
        view "create_course"
    end
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