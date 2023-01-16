require 'sinatra/base'
require 'sinatra/contrib/all'
require 'sqlite3'

class BaltoConsultation < Sinatra::Base
  enable :sessions
  attr_accessor :pet, :pet_name, :sex, :breed, :age_years, :age_months, :age_total_months, :lifestage, :neutered, :body_condition, :nec, :weight_current, :weight_adult, :weight_target, :activity_level, :k2, :recovery_routine, :food_type, :food_brand, :ingredient_exclusion, :dental_brushing, :wellness_issues, :email

  #Initialize variables to store user's answers
    @pet = ""
    @pet_name = ""
    @sex = ""
    @breed = ""
    @age_years = 0
    @age_months = 0
    @age_total_months = 0
    @lifestage = ""
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
    @pet = session[:pet]
    erb :index
  end

  post '/' do
    session[:pet] = params[:pet]
    if session[:pet] == "dog"
      redirect '/pet_name'
    else
      # proceed with cat branch questions
    end
  end

  get '/pet_name' do
    erb :pet_name
  end  

  post '/pet_name' do
    session[:pet_name] = params[:pet_name]
    redirect '/sex'
  end
  
  get '/sex' do
    erb :sex, locals: { pet_name: session[:pet_name] }
  end

  post '/sex' do
    session[:sex] = params[:sex]
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
      redirect '/age_unknown_breed'
    else
      redirect '/age'
    end
  end

  get '/api/breed_tip' do
    db = SQLite3::Database.new 'balto.db'
    @breed = params[:breed]
    tip = db.execute("SELECT tip FROM dog_breeds WHERE name=?", [@breed]).first
    db.close
    content_type :json
    {tip: tip[0]}.to_json
  end

  get '/age_unknown_breed' do
    erb :age_unknown_breed, locals: { pet_name: session[:pet_name] }
  end

  post '/age_unknown_breed' do
    session[:lifestage] = params[:lifestage]
    session[:age_years] = params[:age_years]
    session[:age_months] = params[:age_months]
    session[:age_total_months] = (session[:age_years].to_i * 12) + session[:age_months].to_i
    if session[:lifestage] == "adult"
      if session[:age_total_months] >= 72
        session[:lifestage] = "senior"
      else
        session[:lifestage] = "adult"
      end
    end
    redirect '/dummy'
  end



  get '/age' do
    erb :age, locals: { pet_name: session[:pet_name] }
  end

  post '/age' do
    session[:age_years] = params[:age_years]
    session[:age_months] = params[:age_months]
    
    # convert years to months and add to months
    session[:age_total_months] = (session[:age_years].to_i * 12) + session[:age_months].to_i

    # retrieve the age of adulthood and seniority for the selected breed from the database
    db = SQLite3::Database.new 'balto.db'
    age_adult_months = db.execute("SELECT age_adult_months FROM dog_breeds WHERE name=?", [session[:breed]]).first
    age_senior_years = db.execute("SELECT age_senior_years FROM dog_breeds WHERE name=?", [session[:breed]]).first
    db.close

    # check if age is lesser than age of adulthood
    if session[:age_total_months] < age_adult_months[0]
      session[:lifestage] = "puppy"
    # check if age is greater than or equal to senior age for the breed
    elsif session[:age_years].to_i >= age_senior_years[0]
      session[:lifestage] = "senior"
    # otherwise, lifestage is adult
    else
      session[:lifestage] = "adult"
    end
    redirect '/dummy'
  end

  get '/dummy' do
    erb :dummy, locals: { pet: session[:pet], pet_name: session[:pet_name], sex: session[:sex], breed: session[:breed], age_years: session[:age_years], age_months: session[:age_months], age_total_months: session[:age_total_months], lifestage: session[:lifestage] }
  end


end

BaltoConsultation.run!