class InternalController < ApplicationController

  is_internal!

  def index
    @current_regatta = Regatta.find_by(id: Parameter.current_regatta_id) || Regatta.last
  end

end