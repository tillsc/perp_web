class MeasurementsController < ApplicationController

  before_action do
    @measuring_point = @regatta.measuring_points.find_by!(number: params[:measuring_point_number])
  end

  def current_race
    @race = Race.for_regatta(@regatta).joins(:results).now.first
    show
  end

  def show
    @race||= Race.for_regatta(@regatta).find_by(event_number: params[:event_number], number: params[:race_number])
    @other_races = Race.for_regatta(@regatta).joins(:results).nearby
    render :show
  end

  def save
    @race = race.find(params[:race_id])
  end

end