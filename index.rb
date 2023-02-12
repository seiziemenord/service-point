require 'sinatra/base'
require 'sinatra/contrib/all'
require 'sqlite3'

class BaltoConsultation < Sinatra::Base
  enable :sessions
  attr_accessor :pet, :pet_name, :diet_mix

  #Initialize variables to store user's answers
    @pet = ""

  get '/' do
    erb :index
  end

  post '/' do
    session[:zip] = params[:zip]
    session[:city] = params[:city]
    session[:country] = params[:country]
    redirect '/shipping'
  end

  get '/shipping' do
    erb :shipping, locals: { zip: session[:zip], city: session[:city], country: session[:country]  }
  end  

  post '/shipping' do
    session[:service_point_id] = params[:code]
    redirect '/dummy'
  end

BaltoConsultation.run!
end