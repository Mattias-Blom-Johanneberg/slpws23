require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

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
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    user_id = result["user_id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = user_id
        p session[:id]
        redirect('/watches/favourites')
    else
        "Fel lösenord!"
    end
end

get('/watches/favourites') do
    user_id = session[:id].to_i
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT *, watch_name FROM user_favourites JOIN watches ON user_favourites.watch_id = watches.watch_id WHERE user_id = ?", user_id)
    slim(:"/watches/favourites", locals:{favourites:result})
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
end

get('/watches') do
    db = SQLite3::Database.new('db/watch_database.db')
    db.results_as_hash = true
    result = db.execute("SELECT watch_id, watch_name FROM watches")
    p result
    slim(:"/watches/index",locals:{watches:result})
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
    
    # i = 0
    # already_liked = false
    # p result.length
    # while (already_liked == false) & (i < result.length)
    #     puts result[i].to_i
    #     p i
    #     if result[i] == watch_id
    #         already_liked = true
    #     else
    #         already_liked = false
    #     end
    #     i += 1
    # end
    # p already_liked
    # if already_liked == true
    #     "Du har redan gillat denna klockan!"
    # else
        # db.execute("INSERT INTO user_favourites (user_id, watch_id) VALUES (?,?)", user_id, watch_id)
    # end
    
    db.execute("INSERT INTO user_favourites (user_id, watch_id) VALUES (?,?)", user_id, watch_id)
    redirect('/watches/favourites')
end

get('/watches/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM watches WHERE watch_id = ?", id).first
    slim(:"/watches/show", locals:{result:result})
  end
