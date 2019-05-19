Rails.application.routes.draw do

  scope '/:regatta_id' do

    get '/latest' => 'latest_races#index'
    get '/latest_race' => 'latest_races#show'

    resources :events, only: [:index] do
      get :participants
      get :starts
      resources :results, only: [:index, :show]
    end
  end

  get '/:regatta_id' => 'latest_races#index'

  root :to => redirect { |p, req| "#{Parameter.current_regatta_id}" }

end
