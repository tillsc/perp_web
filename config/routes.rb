Rails.application.routes.draw do

  devise_for :users


  get '/representative/:public_private_id', as: :dummy_representative, to: redirect(status: 307) { |p, req| (req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s) + '/representative/' + req.params["public_private_id"]}

  get '/internal', as: :dummy_internal, to: redirect(status: 307) { |p, req| "#{req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s}/internal" }
  scope '/internal', module: :internal, as: :internal do
    resources :users
  end

  scope '/:regatta_id' do

    get '/internal', to: 'internal#index'
    scope '/internal', module: :internal, as: :internal do
      resources :addresses do
        delete '/regatta/referee' => :remove_regatta_referee
        put '/regatta/referee' => :add_regatta_referee
      end
      resources :events do
        get '/starts' => 'starts#index'
        get '/starts/:race_type' => 'starts#edit', as: 'race_type_starts'
        put '/starts/:race_type' => 'starts#save'
      end
      resources :races
      resources :participants
      resources :teams
      resources :rowers
      resources :measuring_points

      get '/weighings/:date' => 'weighings#index', as: :weighings
      get '/weighings/:date/event/:id' => 'weighings#event', as: :event_weighings
      get '/weighings/:date/rowers' => 'weighings#rowers', as: :rowers_weighings
      get '/weighings/:date/rowers/:id' => 'weighings#rower', as: :rower_weighings
      put '/weighings/:date/rowers/:id' => 'weighings#save_weight'
    end
    get '/tv' => 'latest_races#index'
    put '/tv' => 'latest_races#update'
    get '/current_start' => 'latest_races#current_start'
    get '/latest_race' => 'latest_races#show'
    get '/latest_winner' => 'latest_races#latest_winner'
    get '/results' => 'regatta#all_results'
    get '/upcoming' => 'regatta#upcoming'
    get '/status' => 'state#index'
    get '/rower/:rower_id' => 'regatta#rower', as: :rower

    # Legacy
    get 'representative/:public_private_id', to: redirect(status: 307) { |p, req| "#{req.params["regatta_id"]}/my/#{req.params["public_private_id"]}" }

    get 'my/:public_private_id' => 'my#index', as: :my

    get '/announcer' => 'announcer#index'
    get '/announcer/results/:event_number/:race_number' => 'announcer#results', as: :announcer_results

    get '/measurements' => 'measurements#index', as: :measurements
    get '/measurements/:event_number/:race_number' => 'measurements#show', as: :measurement
    post '/measurements/:event_number/:race_number' => 'measurements#save'

    get '/finish_cam/:event_number/:race_number' => 'measurements#finish_cam', as: :finish_cam_measurement

    resources :measuring_sessions

    scope '/:event_id', as: 'event' do
      get '/participants' => 'regatta#participants'
      get '/starts' => 'regatta#starts'
      get '/results' => 'regatta#results'
    end

  end

  get '/:regatta_id' => 'regatta#show', as: :regatta

  scope '/internal', module: :internal, as: :internal do
    resources :regattas do
      put :activate
    end
  end

  root to: redirect(status: 307) { |p, req| req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s.presence || "/internal/regattas" }

end
