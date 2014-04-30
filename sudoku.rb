require 'sinatra'
require_relative './lib/sudoku'
require_relative './lib/cell'

enable :sessions

def random_sudoku
	seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
	sudoku = Sudoku.new(seed.join)
	sudoku.solve!
	sudoku.to_s.chars
end


def puzzle(random_sudoku)
  probabality = 0.15
  rows = random_sudoku.each_slice(9).map {|row| row.map{|cell| rand()>probabality ? cell : "0"}}.flatten
  column = rows.each_slice(9).to_a.transpose.map {|row| row.map{|cell| cell != "0" && rand()>probabality ? cell : "0"}}
  column.to_a.transpose.flatten
end

def box_to_row(cells)
  rows = cells.each_slice(27).to_a
  rows.map do |row| 
    a = row.each_slice(9).to_a.map{|box| box.each_slice(3)}
    a[0].zip(a[1]).zip(a[2]).flatten
  end
end


get '/' do
  sudoku = random_sudoku
  session[:solution] = sudoku
	@current_solution = puzzle(sudoku)
	erb :index
end

get '/solution' do
  @current_solution = session[:solution]
  erb:index
end