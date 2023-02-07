require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'

get('/')  do
    slim(:start)
end 

get('/watches') do
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT watch_id, watch_name FROM watches")
    p result
    slim(:"watches/index",locals:{watches:result})
end

get('/watches/new') do
    slim(:"watches/new")
end

post('/watches/new') do
    watch_name = params[:watch_name]
    brand_name = params[:brand_name]
    content = params[:content]
    movement = params[:movement]
    watch_id = params[:watch_id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    brand_id = db.execute("SELECT brand_id FROM watch_brands WHERE brand_name = ?", id).first
    db.execute("INSERT INTO watches (watch_name, brand_name, brand_id, content, movement, watch_id) VALUES (?,?,?,?,?,?)", watch_name, brand_name, brand_id, content, movement, watch_id)
end

get('/watches/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/watch_database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM watches WHERE watch_id = ?",id).first
    slim(:"watches/show",locals:{result:result})
  end
