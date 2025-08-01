module Internal
  class TimeScheduleController < ApplicationController

    is_internal!

    before_action do
      @time_schedule_service = Services::TimeSchedule.new(@regatta.races.preload(:event, :starts, :results))
    end

    def index
      authorize! :index, Services::TimeSchedule::Block
    end

    def show
      @block = @time_schedule_service.find(params[:id].to_i)
      authorize! :show, @block
    end

    def set_first_start
      @block = @time_schedule_service.find(params[:id].to_i)
      authorize! :update, @block
      Race.transaction do
        if @block.set_first_start(params[:first_start])
          render plain: "Ok"
        else
          render plain: "Error", status: 500
        end
      end
    end
  end

end