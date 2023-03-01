class InternalController < ApplicationController

  def index
    authorize! :access, :internal

    @current_regatta = Regatta.find(Parameter.current_regatta_id)
  end

end