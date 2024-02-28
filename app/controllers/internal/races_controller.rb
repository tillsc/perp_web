module Internal
  class RacesController < ApplicationController

    is_internal!

    def index
      @races = @regatta.races.preload(:event, :starts, :results)
    end


    def new
      @race = @regatta.races.new(race_params)

      authorize! :new, @race
      prepare_form
    end

    def create
      @race = @regatta.races.new(race_params)
      authorize! :create, @race

      if @race.save
        flash[:info] = 'Lauf angelegt'
        redirect_to back_or_default
      else
        flash[:danger] = "Lauf konnte nicht angelegt werden:\n#{@race.errors.full_messages}"
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
        flash[:info] = 'Lauf aktualisiert'
        redirect_to back_or_default
      else
        flash[:danger] = "Lauf konnte nicht gespeichert werden:\n#{@race.errors.full_messages}"
        prepare_form
        render :edit
      end
    end

    def destroy
      race = @regatta.races.find(params.extract_value(:id))
      authorize! :destroy, race

      if race.destroy
        flash[:info] = 'Lauf gelöscht'
      else
        flash[:danger] = "Lauf konnte nicht gelöscht:\n#{race.errors.full_messages}"
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      anchor = "race_#{@race.to_param}" if @race
      internal_races_url(@regatta, anchor: anchor)
    end

    def prepare_form
      @measuring_points = @regatta.measuring_points
    end

    def race_params(default = {})
      params.fetch(:race, default).permit(:event_number, :type_short, :number_short,
                                          :planned_for, :started_at_time,
                                          :result_official_since, :result_corrected,
                                          :weight_list_approved_at, :weight_list_approved_by)
    end

  end
end