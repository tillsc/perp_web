Rails.application.routes.draw do

  scope '/:regatta_id' do

    get '/latest_race' => 'latest_races#show'
    get '/results' => 'regatta#all_results'
    get '/upcoming' => 'regatta#upcoming'
    get '/status' => 'state#index'

    scope '/:event_id', as: 'event' do
      get '/participants' => 'regatta#participants'
      get '/starts' => 'regatta#starts'
      get '/results' => 'regatta#results'
    end

  end

  get '/:regatta_id' => 'regatta#show', as: :regatta

  root :to => redirect { |p, req| req.params["regatta_id"].presence || Parameter.current_regatta_id.to_s }

end
