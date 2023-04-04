require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

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
    
    if user_login(username, password)
        redirect('/watches/favourites')
    else
        "Fel lösenord!"
    end
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if register_user(username, password, password_confirm)
        redirect('/')
    else 
        "Lösenordet matchade inte!"
    end
end

get('/watches') do
    result = show_watches()
    slim(:"/watches/index", locals:{watches:result})
end

get('/watches/favourites') do
    user_id = session[:id].to_i
    result = show_favourite_watches(user_id)
    slim(:"/watches/favourites", locals:{favourites:result})
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
    register_new_watch(watch_name, brand_name, content, movement, watch_id)
    redirect('/watches')
end

post('/watches/:id/delete') do
    id = params[:id].to_i
    delete_a_watch(id)
    redirect('/watches')
end  

post('/watches/:id/update') do
    id = params[:id].to_i
    watch_name = params[:watch_name]
    brand_id = params[:brand_id].to_i
    update_a_watch(id, watch_name, brand_id)
    redirect('/watches')
end

get('/watches/:id/edit') do
    id = params[:id].to_i
    edit_a_watch(id)
    slim(:"/watches/edit", locals:{result:result})
end

get('/watches/:id/like') do
    watch_id = params[:id].to_i
    user_id = session[:id]

    if like_a_watch(watch_id, user_id)
        "Du har redan gillat denna klockan!"
    else
        redirect('/watches/favourites')
    end
end

get('/watches/:id/dislike') do
    watch_id = params[:id].to_i
    user_id = session[:id]
    dislike_a_watch(watch_id, user_id)
    redirect('/watches/favourites')
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
    result = show_a_watch(id)
    slim(:"/watches/show", locals:{result:result})
  end
