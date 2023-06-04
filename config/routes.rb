Rails.application.routes.draw do

  devise_for :users


  get '/representative/:public_private_id', as: :dummy_representative, to: redirect { |p, req| (req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s) + '/representative/' + req.params["public_private_id"]}

  get '/internal', as: :dummy_internal, to: redirect { |p, req| "#{req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s}/internal" }
  scope '/internal', module: :internal, as: :internal do
    resources :users
  end

  scope '/:regatta_id' do

    get '/internal', to: 'internal#index'
    scope '/internal', module: :internal, as: :internal do
      resources :addresses
      resources :races
    end
    get '/tv' => 'latest_races#index'
    put '/tv' => 'latest_races#update'
    get '/current_start' => 'latest_races#current_start'
    get '/latest_race' => 'latest_races#show'
    get '/latest_winner' => 'latest_races#latest_winner'
    get '/results' => 'regatta#all_results'
    get '/upcoming' => 'regatta#upcoming'
    get '/status' => 'state#index'
    get 'representative/:public_private_id' => 'regatta#representative', as: :representative
    get '/rower/:rower_id' => 'regatta#rower', as: :rower

    get '/announcer' => 'announcer#index'
    get '/announcer/results/:event_number/:race_number' => 'announcer#results', as: :announcer_results

    get '/measurements' => 'measurements#index', as: :measurements
    get '/measurements/:event_number/:race_number' => 'measurements#show', as: :measurement
    post '/measurements/:event_number/:race_number' => 'measurements#save'

    resources :measuring_sessions

    scope '/:event_id', as: 'event' do
      get '/participants' => 'regatta#participants'
      get '/starts' => 'regatta#starts'
      get '/results' => 'regatta#results'
    end

  end

  get '/:regatta_id' => 'regatta#show', as: :regatta

  root :to => redirect { |p, req| req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s }

end
