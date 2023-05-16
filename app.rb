require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

include Model

before('/*') do
    @user_id = session[:id]

    # if session[:error] != nil
    #     redirect('/error')
    # end
end

before('/watches/*') do
    if session[:id] == nil
        session[:error] = "Du behöver logga in för att se denna sidan"
        redirect('/error')
    end
end

before('/watches/show') do
    @admin_check = (session[:id] == 1? true : false)
end

# Displays the landing page
#
# @see Model#start
get('/') do
    user_id, result = start()
    if user_id == nil
        slim(:start)
    else
        slim(:user_start, locals:{user:result})
    end 
end 

# Displays a login form and a link to register account or, if user is logged in, redirects to '/logout'
#
get('/login') do
    if session[:id] != nil
        redirect('/logout')
    else
        slim(:login)
    end
end

# Displays a logout form
#
get('/logout') do
    slim(:logout)
end

# Displays a register form
#
get('/register') do
    slim(:register)
end

# Attempts login and updates the session 
#
# @param [String] username The username
# @param [String] password The password
#
# @see Model#login
post('/login') do
    cooldown()
    username = params[:username]
    password = params[:password]
    attempt, user_id = login(username, password)

    if attempt
        session[:id] = user_id
        redirect('/')
    else
        "Fel lösenord!"
    end
end

# User logs out and session is destroyed
#
post('/logout') do
    session.destroy
    redirect('/')
end

# Attempts login/register and updates the session
#
# @param [String] username The username
# @param [String] password The password
# @param [String] password_confirm The repeated password
#
# @see Model#register_user
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

# Displays a list of all watches
#
# @see Model#show_all_watches
get('/watches/show') do
    result = show_all_watches()
    slim(:"/watches/index", locals:{watches:result, admin:@admin_check})
end

# Displays a list of all watches liked by the user
#
# @see Model#show_favourite_watches
get('/watches/favourites') do
    # user_id = session[:id]
    result = show_favourite_watches(@user_id)
    slim(:"/watches/favourites", locals:{favourites:result})
end

# Displays a form to create/add a watch
#
get('/watches/new') do
    slim(:"/watches/new")
end

# Displays a single watch
#
# @param [Integer] :id The ID of the watch
#
# @see Model#get_watch
get('/watches/:id') do
    id = params[:id].to_i
    result = get_watch(id)
    slim(:"/watches/show", locals:{result:result})
end

# Creates a new watch and redirects to '/watches/show'
#
# @param [String] watch_name The name of the watch
# @param [String] brand_name The name of the brand
# @param [String] content The content of the watch
# @param [String] movement The movement of the watch
# @param [Integer] :watch_id The ID of the watch
#
# @see Model#create_new_watch
post('/watches/new') do
    watch_name = params[:watch_name]
    brand_name = params[:brand_name]
    content = params[:content]
    movement = params[:movement]
    watch_id = params[:watch_id].to_i
    user_id = session[:id].to_i
    create_watch(watch_name, brand_name, content, movement, watch_id, user_id)
    redirect('/watches/show')
end

# Deletes an existing watch and redirects to '/watches/show'
#
# @param [Integer] :id The ID of the user
#
# @see Model#delete_watch
post('/watches/:id/delete') do
    id = params[:id].to_i
    if get_watch_user(id)[0][0] != session[:id]
        session[:error] = "You dont have access to this watch!"
        redirect('/error')
    end
    delete_watch(id)
    redirect('/watches/show')
end  

# Updates an existing watch and redirects to '/watches/show'
#
# @param [Integer] :id The ID of the watch
# @param [String] watch_name The name of the watch
# @param [String] :brand_id The ID of the brand
#
# @see Model#update_watch
post('/watches/:id/update') do
    id = params[:id].to_i
    if get_watch_user(id)[0][0] != session[:id]
        session[:error] = "You dont have access to this watch!"
        redirect('/error')
    end
    watch_name = params[:watch_name]
    brand_id = params[:brand_id].to_i
    update_watch(id, watch_name, brand_id)
    redirect('/watches/show')
end

# Displays an edit form
#
# @param [Integer] :id The ID of the watch
#
# @see Model#edit_watch
get('/watches/:id/edit') do
    id = params[:id].to_i
    if get_watch_user(id)[0][0] != session[:id]
        session[:error] = "You dont have access to this watch"
        redirect('/error')
    end
    result = edit_watch(id)    
    slim(:"/watches/edit", locals:{result:result})
end

# Attempts to adds watch to users favourites and redirects to '/watches/favourites'
#
#
# @param [Integer] :id The ID of the watch
#
# @see Model#like_watch
post('/watches/:id/like') do
    watch_id = params[:id].to_i
    user_id = session[:id]
    

    if like_watch(watch_id, user_id)
        "Du har redan gillat denna klockan!"
    else
        redirect('/watches/favourites')
    end
end

# Deletes watch from users favourites and redirects to '/watches/favourites'
#
# @param [Integer] :id The ID of the watch
#
# @see Model#dislike_watch
post('/watches/:id/dislike') do
    watch_id = params[:id].to_i
    user_id = session[:id]
    dislike_watch(watch_id, user_id)
    redirect('/watches/favourites')
end


# Displays an error message
#
get('/error') do
    error = session[:error]
    slim(:error, locals:{error:error})
end