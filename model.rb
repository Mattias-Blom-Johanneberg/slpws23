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
    #
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

    # Finds elements
    #
    # @return [Hash]
    #   * watch_id [Integer] The IDs of all watches
    #   * watch_name [String] The names of all watches
    #   * user_id [Integer] The ID of the user owner of every watch
    def show_all_watches()
        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        result = db.execute("SELECT watch_id, watch_name, user_id FROM watches")
        return result
    end

    def show_favourite_watches(user_id)
        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        result = db.execute("SELECT * FROM user_favourites JOIN watches ON user_favourites.watch_id = watches.watch_id WHERE user_favourites.user_id = ?", user_id)
        return result
    end

    def create_watch(watch_name, brand_name, content, movement, watch_id, user_id)
        check_input(watch_name)
        check_input(brand_name)
        check_input(content)
        check_input(movement)

        db = SQLite3::Database.new("db/watch_database.db")
        brand_id = db.execute("SELECT brand_id FROM watch_brands WHERE brand_name = ?", brand_name).first
        db.execute("INSERT INTO watches (watch_name, brand_name, brand_id, content, movement, user_id) VALUES (?,?,?,?,?,?)", watch_name, brand_name, brand_id, content, movement, user_id)
    end

    def delete_watch(id)
        db = SQLite3::Database.new("db/watch_database.db")
        db.execute("DELETE FROM watches WHERE watch_id = ?", id)
    end

    def update_watch(id, watch_name, brand_id)
        check_input(watch_name)

        db = SQLite3::Database.new("db/watch_database.db")
        db.execute("UPDATE watches SET watch_name = ?, brand_id = ? WHERE watch_id = ?", watch_name, brand_id, id)
    end

    def edit_watch(id)
        db = SQLite3::Database.new("db/watch_database.db")
        db.results_as_hash = true
        return db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
    end

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

    def dislike_watch(watch_id, user_id)
        db = SQLite3::Database.new("db/watch_database.db")
        db.results_as_hash = true
        db.execute("DELETE FROM user_favourites WHERE user_id = ? AND watch_id = ?", user_id, watch_id)
    end

    def get_watch(id)
        db = SQLite3::Database.new('db/watch_database.db')
        db.results_as_hash = true
        result = db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
        owner = db.execute("SELECT username from users WHERE user_id = ?", result["user_id"])
        result.store("username", owner[0][0])
        return result
    end

end