require 'sinatra/base'
require 'sinatra/contrib/all'
require 'sqlite3'

class BaltoConsultation < Sinatra::Base
  enable :sessions
  attr_accessor :pet, :pet_name, :sex, :breed, :k1, :age_years, :age_months, :age_total_months, :lifestage, :neuter, :k3, :body_condition, :nec, :weight_current, :weight_adult, :weight_target, :activity_level, :k2, :recovery_routine, :food_type, :food_brand, :ingredient_exclusion, :dental_brushing, :dental_chews, :wellness_issues, :email, :age_adult_months, :age_senior_years, :mer, :diet_mix

  #Initialize variables to store user's answers
    @pet = ""
    @pet_name = ""
    @sex = ""
    @breed = ""
    @k1 = ""
    @age_years = 0
    @age_months = 0
    @age_total_months = 0
    @lifestage = ""
    @neuter = ""
    @k3 = 0
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
    @dental_chews = ""
    @wellness_issues = ""
    @email = ""
    @mer = 0
    @diet_mix = []

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
      # Retrieve the age of adulthood and seniority for the selected breed from the database
      db = SQLite3::Database.new 'balto.db'
      age_adult_months = db.execute("SELECT age_adult_months FROM dog_breeds WHERE name=?", [session[:breed]]).first
      age_senior_years = db.execute("SELECT age_senior_years FROM dog_breeds WHERE name=?", [session[:breed]]).first
      k1 = db.execute("SELECT k1 FROM dog_breeds WHERE name=?", [session[:breed]]).first
      db.close
      session[:age_adult_months] = age_adult_months[0].to_i
      session[:age_senior_years] = age_senior_years[0].to_i
      session[:k1] = k1[0].to_f
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
    redirect '/neuter'
  end

  get '/age' do
    erb :age, locals: { pet_name: session[:pet_name] }
  end

  post '/age' do
    session[:age_years] = params[:age_years]
    session[:age_months] = params[:age_months]
    # convert years to months and add to months
    session[:age_total_months] = (session[:age_years].to_i * 12) + session[:age_months].to_i

    # check if age is lesser than age of adulthood
    if session[:age_total_months].to_i < session[:age_adult_months]
      session[:lifestage] = "puppy"
    # check if age is greater than or equal to senior age for the breed
    elsif session[:age_years].to_i >= session[:age_senior_years]
      session[:lifestage] = "senior"

    # otherwise, lifestage is adult
    else
      session[:lifestage] = "adult"
    end
    
    redirect '/neuter'
  end

  get '/neuter' do
    erb :neuter, locals: { pet_name: session[:pet_name] }
  end

  post '/neuter' do
    neuter = params[:neuter]
    if neuter == "yes"
      session[:neuter] = "neutered"
      session[:k3] = 0.8
    else
      session[:neuter] = "not neutered"
      session[:k3] = 1
    end
    redirect '/body_condition'
  end

  get '/body_condition' do
    erb :body_condition, locals: { pet_name: session[:pet_name] }
  end

  post '/body_condition' do
    body_condition = params[:body_condition]
    if body_condition == "skinny"
      session[:body_condition] = "skinny"
      session[:nec] = 3
    elsif body_condition == "perfect"
      session[:body_condition] = "perfect"
      session[:nec] = 5
    else
      session[:body_condition] = "fat"
      session[:nec] = 7
    end
    redirect '/weight_current'
  end

  get '/weight_current' do
    erb :weight_current, locals: { pet_name: session[:pet_name], nec: session[:nec], lifestage: session[:lifestage] }
  end

  post '/weight_current' do
    session[:weight_current] = params[:weight]
    if session[:nec] == 5
      session[:weight_target] = session[:weight_current] 
      redirect '/activity_level'  
    else
      redirect '/weight_specific'
    end
  end
  
  get '/weight_specific' do
    erb :weight_specific, locals: { pet_name: session[:pet_name], lifestage: session[:lifestage], breed: session[:breed], nec: session[:nec] }
  end

post '/weight_specific' do
  if session[:lifestage] == "puppy"
    session[:weight_adult] = params[:weight_adult]
      if session[:breed] != "Unknown breed"
        if session[:weight_adult] == "Unknown"
          # Recalls dog adult weight depending on sex from breeds DB
          db = SQLite3::Database.new 'balto.db'
            if session[:sex] == "male" 
              weight_adult = db.execute("SELECT weight_adult_male FROM dog_breeds WHERE name=?", [session[:breed]]).first
            else
              weight_adult = db.execute("SELECT weight_adult_female FROM dog_breeds WHERE name=?", [session[:breed]]).first
            end
          db.close
          session[:weight_adult] = weight_adult[0].to_i
        else
          session[:weight_adult] = params[:weight_adult].to_i
        end
      else
        session[:weight_adult] = params[:weight_adult].to_i
      end
  elsif session[:nec] != 5
    if params[:weight_target] == "Unknown"
      session[:weight_target] = (session[:weight_current].to_f * (100 / (100 + ((session[:nec].to_f - 5 ) * 10)))).round
    else 
      session[:weight_target] = params[:weight_target].to_i
    end
  redirect '/activity_level'
  end
end

  get '/activity_level' do
    erb :activity_level, locals: { pet_name: session[:pet_name] }
  end

  post '/activity_level' do
    activity_level = params[:activity_level]
    if activity_level == "lazy"
      session[:activity_level] = "lazy"
      session[:k2] = 0.8
    elsif activity_level == "normal"
      session[:activity_level] = "normal"
      session[:k2] = 0.9
    else
      session[:activity_level] = "very active"
      session[:k2] = 1.1
      session[:recovery_routine] = params[:recovery_routine]
    end
    redirect '/food'
  end

  get '/food' do
    db = SQLite3::Database.new 'balto.db'
    food_brands = db.execute("SELECT name FROM food_brands").flatten
    db.close
    erb :food, locals: {food_brands: food_brands, pet_name: session[:pet_name]}
  end
    
  post '/food' do
    session[:food_type] = params[:food_type]
    session[:food_brand] = params[:food_brand]
    redirect '/ingredient_exclusion'
  end  
  
  # Tip currently not working - to be fixed later
  get '/api/brand_tip' do
    puts params[:brand]
    db = SQLite3::Database.new 'balto.db'
    @brand = params[:brand]
    brand_tip = db.execute("SELECT comment FROM food_brands WHERE name=?", [@brand]).first
    db.close
    content_type :json
    {brand_tip: brand_tip[0]}.to_json
end

get '/ingredient_exclusion' do
  erb :ingredient_exclusion, locals: { pet_name: session[:pet_name] }
end

post '/ingredient_exclusion' do
  session[:ingredient_exclusion] = params[:ingredient_exclusion]
  redirect '/dental_care'
end

get '/dental_care' do
  erb :dental_care, locals: { pet_name: session[:pet_name] }
end

post '/dental_care' do
  session[:dental_brushing] = params[:dental_brushing]
  session[:dental_chews] = params[:dental_chews]
  redirect '/issues'
  end

  get '/issues' do
    db = SQLite3::Database.new 'balto.db'
    issues = db.execute("SELECT issue_name FROM wellness_issues").flatten
    db.close
    erb :issues, locals: {issues: issues, pet_name: session[:pet_name]}
  end
    
    post '/issues' do
    session[:wellness_issues] = params[:issues]
    redirect '/email'
    end

    get '/email' do
      erb :email, locals: {pet_name: session[:pet_name]}
    end
    
    post '/email' do
      session[:email] = params[:email]

      # Calcs - Pet caloric needs 
      if session[:pet] == "dog"
        if session[:lifestage] != "puppy" 
          session[:mer] = ((session[:weight_target].to_f ** 0.75) * 130 * session[:k2].to_f * session[:k3].to_f).round
        else
          session[:mer] = ((254 - (135 * session[:weight_current].to_f / session[:weight_adult].to_f)) * (session[:weight_current].to_f ** 0.75)).round
        end
      end

      # Determine diet mix
      def determine_diet_mix(food_type)
        if food_type.all? { |type| type == "Dry food" }
          diet_mix = {"dry" => "100%", "wet" => "0%"}
        else
          diet_mix = {"dry" => "75%", "wet" => "25%"}
        end
        return diet_mix
      end
      session[:diet_mix] = determine_diet_mix(session[:food_type])
    
    
      # Product recommendation function
      def determine_product_recommendations(diet_mix, lifestage, weight_current, nec, ingredient_exclusion)
        product_recommendations = {}
        db = SQLite3::Database.open "balto.db"
      
        # Convert ingredient_exclusion to an array of lowercase strings
        ingredient_exclusion = ingredient_exclusion.map{|ingredient| ingredient.downcase}.join(",").split(",")
      
        # Determine dry food product recommendations
        if diet_mix.include?("dry")
          dry_recommendations = []
          if lifestage == "puppy"
            if weight_current < 5
              dry_recommendations << "SGF"
            else
              dry_recommendations += ["PES", "AES", "SES"]
            end
          elsif lifestage == "senior" || nec == 7
            dry_recommendations += ["DES", "PES", "AES", "SES"]
          else
            dry_recommendations += ["PES", "AES", "SES"]
          end
        end
          # Exclude products that contain ingredients in ingredient_exclusion
          ingredient_exclusion = ingredient_exclusion.map{|ingredient| ingredient.downcase}.join(",").split(",")
          dry_recommendations.each do |product_id|
            protein_sources = db.execute("SELECT protein_sources FROM products WHERE product_ID = ? LIMIT 1", product_id)[0][0].to_s.split(",").map(&:downcase)
            if (protein_sources & ingredient_exclusion).empty?
              product_recommendations["dry"] ||= []
              product_recommendations["dry"] << product_id
            end
          end
      
      
        # Determine wet food product recommendations
        # ... code to determine wet food product recommendations goes here ...
        # ... and don't forget to exclude products that contain ingredients in ingredient_exclusion ...
      
        return product_recommendations
      end
      
      session[:product_recommendations] = determine_product_recommendations(session[:diet_mix], session[:lifestage], session[:weight_current], session[:nec], session[:ingredient_exclusion])
      
      redirect '/dummy'
    end

  get '/dummy' do
    erb :dummy, locals: {
      pet: session[:pet],
      pet_name: session[:pet_name],
      sex: session[:sex],
      breed: session[:breed],
      k1: session[:k1],
      age_years: session[:age_years],
      age_months: session[:age_months],
      age_total_months: session[:age_total_months],
      lifestage: session[:lifestage],
      neuter: session[:neuter],
      k3: session[:k3],
      body_condition: session[:body_condition],
      nec: session[:nec],
      weight_current: session[:weight_current],
      weight_adult: session[:weight_adult],
      weight_target: session[:weight_target],
      activity_level: session[:activity_level], 
      k2: session[:k2],
      recovery_routine: session[:recovery_routine],
      food_type: session[:food_type],
      food_brand: session[:food_brand],
      ingredient_exclusion: session[:ingredient_exclusion],
      dental_brushing: session[:dental_brushing],
      dental_chews: session[:dental_chews],
      wellness_issues: session[:wellness_issues],
      email: session[:email],
      mer: session[:mer],
      diet_mix: session[:diet_mix],
      protein_sources: session[:protein_sources],
      product_recommendations: session[:product_recommendations] }
    
  end

BaltoConsultation.run!
end