# The functions for app.rb
module Model

    # Checks input and redirects to '/error' if input is wrong
    #
    # @param [String] input The input to check
    #
    def check_input(input)
        if input == " "
            session[:error] = "Input måste bestå av minst ett tecken annat än mellanslag"
            redirect('/error')
        end
    end

    # Cooldown for login
    #
    def cooldown()
        timenow = Time.now
        if session[:time] == nil
        session[:time] = [timenow]
        else
        session[:time].prepend(timenow)
        end
        timediff = timenow.to_i-session[:time][1].to_i
        if timediff < 10 && session[:time].length > 1
            sleep(2)
        end
    end

    # Shows landing page 
    #
    # @param [Integer] user_id The ID of the user
    def start(user_id)
        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        
        if user_id == nil
            slim(:start)
        else
            result = db.execute("SELECT username FROM users WHERE user_id = ?", user_id)
            slim(:user_start, locals:{user:result})
        end
    end

    # Attempts to login
    #
    # @param [String] username The username of the user
    # @param [String] password The password of the user
    #
    # @return [Boolean] If password was correct or not
    #
    # @see Model#check_input
    def login(username, password)
        check_input(username)
        check_input(password)

        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        result = db.execute("SELECT * FROM users WHERE username = ?", username).first
        
        pwdigest = result["pwdigest"]
        user_id = result["user_id"]

        if BCrypt::Password.new(pwdigest) == password
            session[:id] = user_id
            return true
        else
            return false
        end
    end

    # Attempts to register
    #
    # @param [String] username The chosen username 
    # @param [String] password The chosen password 
    # @param [String] password_confirm The repeated password 
    #
    # @return [Boolean] If repeated password was correct or not
    #
    # @see Model#check_input
    def register_user(username, password, password_confirm)
        
        check_input(username)
        check_input(password)

        if (password == password_confirm)
            password_digest = BCrypt::Password.create(password)
            db = SQLite3::Database.new('db/watch_database.db')
            db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)", username, password_digest)
            return true
        else 
            return false
        end
    end

    # Gathers information about watches
    #
    # @return [Hash]
    #   * watch_id [Integer] The IDs of all watches
    #   * watch_name [String] The names of all watches
    #   * user_id [Integer] The IDs of the owners of every watch
    def show_all_watches()
        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        result = db.execute("SELECT watch_id, watch_name, user_id FROM watches")
        return result
    end

    # Gathers information about favourited watches
    #
    # @param [Integer] user_id The ID of the user
    #
    # @return [Hash] Information from tables 'user_favourites' and 'watches'
    #   * user_id [Integer] The ID of the user 
    #   * watch_id [Integer] The IDs of the watches
    #   * watch_name [String], The names of the watches
    #   * brand_name [String], The names of the brandes
    #   * content [String], The contents of the watches
    #   * movement [String], The movements of the watches
    def show_favourite_watches(user_id)
        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        result = db.execute("SELECT * FROM user_favourites JOIN watches ON user_favourites.watch_id = watches.watch_id WHERE user_favourites.user_id = ?", user_id)
        return result
    end

    # Attempts to create new watch
    #
    # @param [String] watch_name, The names of the watches
    # @param [String] brand_name, The names of the brands
    # @param [String] content, The contents of the watches
    # @param [String] movement, The movements of the watches
    # @param [Integer] watch_id, The IDs of the watches  
    # @param [Integer] userid, The ID of the user    
    #
    # @see Model#check_input
    def create_watch(watch_name, brand_name, content, movement, watch_id, user_id)
        check_input(watch_name)
        check_input(brand_name)
        check_input(content)
        check_input(movement)

        db = SQLite3::Database.new("db/watch_database.db")
        brand_id = db.execute("SELECT brand_id FROM watch_brands WHERE brand_name = ?", brand_name).first
        db.execute("INSERT INTO watches (watch_name, brand_name, brand_id, content, movement, user_id) VALUES (?,?,?,?,?,?)", watch_name, brand_name, brand_id, content, movement, user_id)
    end

    # Deletes a watch
    #
    # @param [Integer] id watch_id
    def delete_watch(id)
        db = SQLite3::Database.new("db/watch_database.db")
        db.execute("DELETE FROM watches WHERE watch_id = ?", id)
    end

    # Updates a watch
    #
    # @param [Integer] id The ID of the watch
    # @param [String] watch_name The name of the watch
    # @param [Integer] brand_id The ID of the brand
    #
    # @see Model#check_input
    def update_watch(id, watch_name, brand_id)
        check_input(watch_name)

        db = SQLite3::Database.new("db/watch_database.db")
        db.execute("UPDATE watches SET watch_name = ?, brand_id = ? WHERE watch_id = ?", watch_name, brand_id, id)
    end

    # Edits a watch
    #
    # @param [Integer] id The id of the watch
    #
    # @return [Hash] Information from tables 'watches'
    #   * watch_id [Integer] The IDs of the watches
    #   * watch_name [String] The names of the watches
    #   * brand_name [String] The names of the brands
    #   * content [String] The contents of the watches
    #   * movement [String] The movements of the watches
    #   * user_id [Integer] The ID of the user 
    def edit_watch(id)
        db = SQLite3::Database.new("db/watch_database.db")
        db.results_as_hash = true
        return db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
    end

    # Check if a watch is already liked
    #
    # @param [Integer] watch_id The ID of the watch
    # @param [Hash] result The IDs of the watches liked by user
    #
    # @return [Boolean] If watch is already liked or not
    def already_liked?(watch_id, result)
        i = 0
        while i < result.length
            if watch_id == result[i][0]
                return true
            end
        i += 1
        end
        return false
    end

    # Attempts to like a watch
    #
    # @params [Integer] watch_id The ID of the watch
    #
    # @return [Boolean] If watch was liked or not
    def like_watch(watch_id, user_id)  
        db = SQLite3::Database.new("db/watch_database.db")
        db.results_as_hash = true
        result = db.execute("SELECT watch_id FROM user_favourites WHERE user_id = ?", user_id)
        
        i = 0
        while i < result.length
            if already_liked?(watch_id, result)
                return true
            end
            i += 1
        end
        
        db.execute("INSERT INTO user_favourites (user_id, watch_id) VALUES (?,?)", user_id, watch_id)
        return false
    end

    # Dislikes a watch
    #
    # @param [Integer] watch_id The ID of the watch
    # @param [Integer] user_id The ID of the user
    def dislike_watch(watch_id, user_id)
        db = SQLite3::Database.new("db/watch_database.db")
        db.results_as_hash = true
        db.execute("DELETE FROM user_favourites WHERE user_id = ? AND watch_id = ?", user_id, watch_id)
    end

    # Gathers information about a specific watch
    #
    # @param [Integer] id The ID of the watch
    #
    # @return [Hash] Information from tables 'watches' and 'users'
    #   * watch_id [Integer] The ID of the watch
    #   * watch_name [String] The name of the watch
    #   * brand_name [String] The name of the brand
    #   * content [String] The content of the watch
    #   * movement [String] The movement of the watche
    #   * user_id [Integer] The ID of the user 
    #   * username [String] The name of the owner of the watch
    def get_watch(id)
        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        result = db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
        owner = db.execute("SELECT username from users WHERE user_id = ?", result["user_id"])
        result.store("username", owner[0][0])
        return result
    end

end