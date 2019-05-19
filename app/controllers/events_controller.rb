class EventsController < ApplicationController

  def index
    @events = Event.where(:regatta => @regatta)
  end

end
