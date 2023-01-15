require 'sinatra/base'
require 'sinatra/contrib/all'
require 'sqlite3'

class BaltoConsultation < Sinatra::Base
  enable :sessions
  attr_accessor :pet, :pet_name, :sex, :breed, :age_years, :age_months, :age_total_months, :neutered, :body_condition, :nec, :weight_current, :weight_adult, :weight_target, :activity_level, :k2, :recovery_routine, :food_type, :food_brand, :ingredient_exclusion, :dental_brushing, :wellness_issues, :email

  #Initialize variables to store user's answers
  @pet = ""
  @pet_name = ""
  @sex = ""
  @breed = ""
  @age_years = 0
  @age_months = 0
  @age_total_months = 0
  @neutered = ""
  @body_condition = ""
  @nec = 0
  @weight_current = 0
  @weight_adult = 0
  @weight_target = 0
  @activity_level = ""
  @k2 = 0
  @recovery_routine = ""
  @food_type = ""
  @food_brand = ""
  @ingredient_exclusion = ""
  @dental_brushing = ""
  @wellness_issues = ""
  @email = ""

  get '/' do
    erb :index
  end

  post '/' do
    @pet = params[:pet]
    if @pet == "dog"
      erb :pet_name
    else
      # proceed with cat branch questions
    end
  end

  post '/pet_name' do
    session[:pet_name] = params[:pet_name]
    redirect '/sex'
  end

  get '/sex' do
    erb :sex, locals: { pet_name: session[:pet_name] }
  end

  post '/sex' do
    @sex = params[:pet_sex]
    redirect '/breed'
  end

  get '/breed' do
    db = SQLite3::Database.new 'balto.db'
    breeds = db.execute("SELECT name FROM dog_breeds").flatten
    db.close
    erb :breed, locals: {breeds: breeds, pet_name: session[:pet_name]}
end

post '/breed' do
  session[:breed] = params[:breed]
  if params[:breed] == "Unknown breed"
    redirect '/age-unknown-breed'
  else
      redirect '/age'
  end
  content_type :json
  {tip: tip}.to_json
end


  get '/api/breed_tip' do
    db = SQLite3::Database.new 'balto.db'
    @breed = params[:breed]
    tip = db.execute("SELECT tip FROM dog_breeds WHERE name=?", [@breed]).first
    db.close
    content_type :json
    {tip: tip[0]}.to_json
end

get '/age-unknown-breed' do
  erb :age_unknown_breed, locals: { pet_name: session[:pet_name] }
end

post '/age-unknown-breed' do
  session[:age_group] = params[:age_group]
  session[:age_years] = params[:age_years]
  session[:age_months] = params[:age_months]

  # convert years to months and add to months
  session[:age_total_months] = (session[:age_years].to_i * 12) + session[:age_months].to_i

  if session[:age_group] == "adult"
    # check if age is greater than or equal to senior age for unknown breeds
    if session[:age_total_months] >= 72
      session[:lifestage] = "senior"
    else
      session[:lifestage] = "adult"
    end
  end

  redirect '/next_question'
end


end

BaltoConsultation.run!