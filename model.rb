def user_login(username, password)
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    user_id = result["user_id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = user_id
        redirect('/watches/favourites')
    else
        "Fel lösenord!"
    end
end

def register_user(username, password, password_confirm)
    
end

def show_watches()
    
end

def show_favourite_watches(user_id)
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user_favourites JOIN watches ON user_favourites.watch_id = watches.watch_id WHERE user_id = ?", user_id) 
end