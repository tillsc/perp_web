Rails.application.routes.draw do

  scope '/:regatta_id' do

    get '/latest_race' => 'latest_races#show'

    resources :events, only: [:index] do
      get :participants
      get :starts
      get :results
    end

    get '/status' => 'state#index'
  end

  get '/:regatta_id' => 'events#index', as: :regatta

  root :to => redirect { |p, req| "#{Parameter.current_regatta_id}" }

end
