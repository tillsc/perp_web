module Internal
  class WeighingsController < ApplicationController

    def index
      @events = @regatta.events.to_be_weighed
    end

  end
end