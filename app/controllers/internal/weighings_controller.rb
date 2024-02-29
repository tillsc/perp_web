module Internal
  class WeighingsController < ApplicationController

    is_internal!

    before_action :parse_date

    def index
      @events = @regatta.events.to_be_weighed.with_weight_info(@date)
    end

    def event
      @event = @regatta.events.to_be_weighed.find(params.extract_value(:id))
      @participants = @event.participants.
        with_weight_info(@date).
        preload(:team, Participant::ALL_ROWERS_WITH_WEIGHTS)
    end

    def rower
      @rower = Rower.find(params[:id])
    end

    def save_weight
      rower = Rower.find(params[:id])
      weight = rower.weight_for(@date) || rower.weights.build(date: @date)
      time = DateTime.parse(params[:time])
      weight.date = weight.date.change(hour: time.hour, min: time.minute, sec: time.second)
      weight.weight = params[:weight]
      weight.save!
      flash[:info] = "Gewicht gespeichert"
      redirect_to params[:referrer] || internal_rower_weighings_url(@regatta, @date, rower)
    end

    protected

    def parse_date
      @date = params[:date].to_date
    end

  end
end