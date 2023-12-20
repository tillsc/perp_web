class InternalController < ApplicationController

  def index
    authorize! :access, :internal

    @current_regatta = Regatta.find_by(id: Parameter.current_regatta_id) || Regatta.last
  end

end