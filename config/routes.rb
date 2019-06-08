Rails.application.routes.draw do

  scope '/:regatta_id' do

    get '/latest_race' => 'latest_races#show'

    scope '/:event_id', as: 'event' do
      get '/participants' => 'regatta#participants'
      get '/starts' => 'regatta#starts'
      get '/results' => 'regatta#results'
    end

    get '/upcoming' => 'regatta#upcoming'
    get '/status' => 'state#index'
  end

  get '/:regatta_id' => 'regatta#show', as: :regatta

  root :to => redirect { |p, req| "#{Parameter.current_regatta_id}" }

end
