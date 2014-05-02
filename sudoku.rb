require 'sinatra'
require 'sinatra/partial'
require 'rack-flash'

use Rack::Flash
set :partial_template_engine,:erb

require_relative './lib/sudoku'
require_relative './lib/cell'

enable :sessions


set :session_secret, "This is a secret key to sign the cookie"


def random_sudoku
	seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
	sudoku = Sudoku.new(seed.join)
	sudoku.solve!
	sudoku.to_s.chars
end


def rand_select(cells_to_blank, array, max=7)
  base_case = (cells_to_blank == 0) || (array.select{|x| x == '0'}.count >= max)
  return array if cells_to_blank == 0
  random = rand(0..8)
  if array[random] == '0'
    return rand_select(cells_to_blank, array, max)
  else
    array[random] = '0'
    rand_select(cells_to_blank-1, array, max)
  end
end

def puzzle(sudoku, difficulty)
	# difficulty.nil? ? difficulty=4 : difficulty
  boxes = box_to_row(sudoku).each_slice(9).map{|box| rand_select(difficulty, box)}.flatten
  rows = box_to_row(boxes)
end

def box_to_row(cells)
  rows = cells.each_slice(27).to_a
  rows.map do |row| 
    a = row.each_slice(9).to_a.map{|box| box.each_slice(3)}
    a[0].zip(a[1]).zip(a[2])
  end.flatten
end

post '/new game' do
  session.clear
  difficulty = {"Easy" => 4, "Medium" => 5, "Hard" => 6}
  session[:cells_to_delete] = difficulty[params[:level]]
  session[:current_solution] = false
  session[:check_solution] = nil
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
  @solution = session[:solution]
  @puzzle = session[:puzzle]
	erb :index
end

def generate_new_puzzle_if_necessary
  return if session[:current_solution]
  sudoku = random_sudoku
  session[:solution]=sudoku
  session[:puzzle]=puzzle(sudoku, session[:cells_to_delete])
  session[:current_solution]=session[:puzzle]
end

def prepare_to_check_solution
  @check_solution = session[:check_solution]
  if @check_solution
    flash[:notice] = "Incorrect values are highlighted in yellow"
  end
  session[:check_solution] = nil
end

get '/solution' do
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  @check_solution = session[:check_solution]
  @current_solution = session[:solution]
  erb:index
end

helpers do 
 
  def cell_value(value)
    value.to_i == 0 ? "" : value
  end

 def colour_class(solution_to_check,puzzle_value,current_solution_value,solution_value)
    must_be_guessed = (puzzle_value == "0")
    tried_to_guess = (current_solution_value.to_i != 0)
    guessed_incorrectly = (current_solution_value != solution_value)

    if solution_to_check &&
      must_be_guessed &&
      tried_to_guess &&
      guessed_incorrectly
      'incorrect'
    elsif !must_be_guessed
      'value_provided'
    end
  end

end
