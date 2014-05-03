require 'sinatra'
require 'sinatra/partial'
require 'rack-flash'

configure :production do
  require 'newrelic_rpm'
end

use Rack::Flash
set :partial_template_engine,:erb
set :session_secret, "This is a secret key to sign the cookie"

configure :production do
  require 'newrelic_rpm'
end

require_relative './lib/sudoku'
require_relative './lib/cell'
require_relative './lib/web_methods'

enable :sessions


post '/new game' do
  session.clear
  difficulty = {"Easy" => 4, "Medium" => 5, "Hard" => 6}
  session[:cells_to_delete] = difficulty[params[:level]]
  session[:current_solution] = false
  session[:check_solution] = nil
  session[:saved_game] = false
  redirect to("/")
end

post '/' do
  cells = box_to_row(params['cell'])
  session[:current_solution] = cells.map{|value| value.to_i}.join
  session[:check_solution] = true 
  redirect to("/")
end

get '/' do
  session[:cells_to_delete] ||= 4
  prepare_to_check_solution
  generate_new_puzzle_if_necessary
  @current_solution = session[:current_solution] || session[:puzzle]
  # @current_solution = session[:current_solution] || session[:puzzle] 
  @solution = session[:solution]
  @puzzle = session[:puzzle]
	erb :index
end

get '/solution' do
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  @check_solution = session[:check_solution]
  @current_solution = session[:solution]
  erb:index
end


