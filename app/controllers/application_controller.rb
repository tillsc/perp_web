class ApplicationController < ActionController::Base

  before_action do
    @regatta = Regatta.find(params[:regatta_id]) if params[:regatta_id]
    @regattas = Regatta.valid
  end

end
