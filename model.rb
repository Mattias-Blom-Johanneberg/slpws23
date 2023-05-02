def check_input(input)
    if input == " "
        session[:error] = "Input måste bestå av minst ett tecken annat än mellanslag"
        redirect('/error')
    end
end

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

def user_login(username, password)
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

def show_watches()
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT watch_id, watch_name FROM watches")
end

def show_favourite_watches(user_id)
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user_favourites JOIN watches ON user_favourites.watch_id = watches.watch_id WHERE user_id = ?", user_id) 
end

def register_new_watch(watch_name, brand_name, content, movement, watch_id, user_id)
    check_input(watch_name)
    check_input(brand_name)
    check_input(content)
    check_input(movement)

    db = SQLite3::Database.new("db/watch_database.db")
    brand_id = db.execute("SELECT brand_id FROM watch_brands WHERE brand_name = ?", brand_name).first
    db.execute("INSERT INTO watches (watch_name, brand_name, brand_id, content, movement, user_id) VALUES (?,?,?,?,?,?)", watch_name, brand_name, brand_id, content, movement, user_id)
end

def delete_a_watch(id)
    db = SQLite3::Database.new("db/watch_database.db")
    db.execute("DELETE FROM watches WHERE watch_id = ?", id)
end

def update_a_watch(id, watch_name, brand_id)
    db = SQLite3::Database.new("db/watch_database.db")
    db.execute("UPDATE watches SET watch_name = ?, brand_id = ? WHERE watch_id = ?", watch_name, brand_id, id)

    check_input(watch_name)
end

def edit_a_watch(id)
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

def like_a_watch(watch_id, user_id)
    puts watch_id, user_id
    
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

def dislike_a_watch(watch_id, user_id)
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    db.execute("DELETE FROM user_favourites WHERE user_id = ? AND watch_id = ?", user_id, watch_id)
end

# def dislike_a_watch_from_favourites()

# end

def show_a_watch(id)
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
    owner = db.execute("SELECT username WHERE user_id = ?", result['user_id'])
end