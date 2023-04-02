require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

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

get('/')  do
    slim(:start)
end 

get('/login') do
    slim(:login)
end

get('/register') do
    slim(:register)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    user_login(username, password)
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    
    if (password == password_confirm)
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new('db/watch_database.db')
        db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)", username, password_digest)
        redirect('/')
    else 
        "Lösenordet matchade inte!"
    end

    # register_user(username, password, password_confirm)
end

get('/watches') do
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT watch_id, watch_name FROM watches")
    slim(:"/watches/index", locals:{watches:result})

    # show_watches()
end

get('/watches/favourites') do
    user_id = session[:id].to_i
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user_favourites JOIN watches ON user_favourites.watch_id = watches.watch_id WHERE user_id = ?", user_id) 
    slim(:"/watches/favourites", locals:{favourites:result})

    # show_favourite_watches(user_id)
end

get('/watches/new') do
    slim(:"/watches/new")
end

post('/watches/new') do
    watch_name = params[:watch_name]
    brand_name = params[:brand_name]
    content = params[:content]
    movement = params[:movement]
    watch_id = params[:watch_id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    brand_id = db.execute("SELECT brand_id FROM watch_brands WHERE brand_name = ?", brand_name).first
    db.execute("INSERT INTO watches (watch_name, brand_name, brand_id, content, movement) VALUES (?,?,?,?,?)", watch_name, brand_name, brand_id, content, movement)
    redirect('/watches')
end

post('/watches/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    db.execute("DELETE FROM watches WHERE watch_id = ?", id)
    redirect('/watches')
end  

post('/watches/:id/update') do
    id = params[:id].to_i
    watch_name = params[:watch_name]
    brand_id = params[:brand_id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    db.execute("UPDATE watches SET watch_name = ?, brand_id = ? WHERE watch_id = ?", watch_name, brand_id, id)
    redirect('/watches')
end

get('/watches/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
    slim(:"/watches/edit", locals:{result:result})
end

get('/watches/:id/like') do
    watch_id = params[:id].to_i
    user_id = session[:id]
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT watch_id FROM user_favourites WHERE user_id = ?", user_id)
    
    i = 0
    already_liked = true
    while already_liked == true && i < result.length
        if already_liked?(watch_id, result)
            return "Du har redan gillat denna klockan!"
        else
            already_liked = false
        end
        i += 1
    end

    if already_liked == false
        db.execute("INSERT INTO user_favourites (user_id, watch_id) VALUES (?,?)", user_id, watch_id)
    end

    redirect('/watches/favourites')
end

get('/watches/:id/dislike') do
    watch_id = params[:id].to_i
    user_id = session[:id]
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    db.execute("DELETE FROM user_favourites WHERE user_id = ? AND watch_id = ?", user_id, watch_id)
    redirect('/watches')
end

get('/watches/favourites/:id/dislike') do
    watch_id = params[:id].to_i
    user_id = session[:id]
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    db.execute("DELETE FROM user_favourites WHERE user_id = ? AND watch_id = ?", user_id, watch_id)
    redirect('/watches/favourites')
end

get('/watches/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
    slim(:"/watches/show", locals:{result:result})
  end
