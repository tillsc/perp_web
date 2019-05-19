Rails.application.routes.draw do

  scope '/:regatta_id' do

    get '/latest' => 'latest_races#index'
    get '/latest_race' => 'latest_races#show'

    resources :events, only: [:index, :show]
  end

  get '/:regatta_id' => 'latest_races#index'

  root :to => redirect { |p, req| "#{Parameter.current_regatta_id}" }

end
