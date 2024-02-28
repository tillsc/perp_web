module Internal
  class WeighingsController < ApplicationController

    is_internal!

    def index
      @events = @regatta.events.to_be_weighed
    end

  end
end