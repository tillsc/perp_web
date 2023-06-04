module Internal
  class RacesController < ApplicationController

    def index
      @races = @regatta.races.preload(:event, :starts, :results)
    end

  end
end