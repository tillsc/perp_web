class ApplicationController < ActionController::Base

  before_action do
    @regatta = Regatta.find(params[:regatta_id])
  end

end
