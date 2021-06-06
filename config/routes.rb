Rails.application.routes.draw do

  scope '/:regatta_id' do

    get '/latest_race' => 'latest_races#show'
    get '/latest_winner' => 'latest_races#latest_winner'
    get '/results' => 'regatta#all_results'
    get '/upcoming' => 'regatta#upcoming'
    get '/status' => 'state#index'
    get 'representative/:public_private_id' => 'regatta#representative', as: :representative
    get '/rower/:rower_id' => 'regatta#rower', as: :rower

    get '/measurements/:measuring_point_number/current_race' => 'measurements#current_race', as: :measurements_current_race
    get '/measurements/:measuring_point_number/:event_number/:race_number' => 'measurements#show', as: :measurements

    scope '/:event_id', as: 'event' do
      get '/participants' => 'regatta#participants'
      get '/starts' => 'regatta#starts'
      get '/results' => 'regatta#results'
    end

  end

  get '/:regatta_id' => 'regatta#show', as: :regatta

  get '/representative/:public_private_id', :to => redirect { |p, req| (req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s) + '/representative/' + req.params["public_private_id"]}

  root :to => redirect { |p, req| req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s }

end
