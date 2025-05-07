module Internal
  class RacesController < ApplicationController

    is_internal!

    def index
      authorize! :index, Race
      @races = @regatta.races.preload(:event, :starts, :results)
    end

    def show
      @race = @regatta.races.find(params.extract_value(:id))
      authorize! :show, @race
    end

    def new
      @race = @regatta.races.new(race_params(number_short: 1, planned_for: DateTime.now))

      authorize! :new, @race
      prepare_form
    end

    def create
      @race = @regatta.races.new(race_params)
      authorize! :create, @race

      if @race.save
        flash[:info] = helpers.success_message_for(:create, @race)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:create, @race)
        prepare_form
        render :new
      end
    end

    def edit
      @race = @regatta.races.find(params.extract_value(:id))
      authorize! :edit, @race
      prepare_form
    end

    def update
      @race = @regatta.races.find(params.extract_value(:id))
      authorize! :update, @race

      if @race.update(race_params)
        flash[:info] = helpers.success_message_for(:update, @race)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @race)
        prepare_form
        render :edit
      end
    end

    def destroy
      race = @regatta.races.find(params.extract_value(:id))
      authorize! :destroy, race

      if race.destroy
        flash[:info] = helpers.success_message_for(:destroy, race)
      else
        flash[:danger] = helpers.error_message_for(:destroy, race)
      end
      redirect_to back_or_default
    end

    def destroy_result
      race = @regatta.races.find(params.extract_value(:race_id))
      result = race.results.find(params.extract_value(:id))
      authorize! :destroy, result

      if result.destroy
        flash[:info] = helpers.success_message_for(:destroy, result)
      else
        flash[:danger] = helpers.error_message_for(:destroy, result)
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      internal_races_url(@regatta, anchor: @race&.to_anchor)
    end

    def prepare_form
      @regatta.events = @regatta.events.preload([])
      @measuring_points = @regatta.measuring_points
    end

    def race_params(default = {})
      params.fetch(:race, default).permit(:event_number, :type_short, :number_short,
                                          :planned_for, :started_at_time,
                                          :result_confirmed_since, :result_official_since, :result_corrected,
                                          :weight_list_approved_at, :weight_list_approved_by)
    end

  end
end