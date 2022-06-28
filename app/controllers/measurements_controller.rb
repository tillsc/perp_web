class MeasurementsController < ApplicationController

  before_action do
    @measuring_session = MeasuringSession.for_regatta(@regatta).find_by(identifier: params[:measuring_session_id])
    @measuring_point = if @measuring_session
                         @measuring_session.active_measuring_point
                       else
                         raise "Not allowed" unless params[:fixme] == '1'
                         @regatta.measuring_points.find_by!(number: params[:measuring_point_number])
                       end
    @race = Race.
      for_regatta(@regatta).
      find_by!(event_number: params[:event_number], number: params[:race_number])
    @measuring = Services::Measuring.new(@measuring_session, @race)
  end

  def show
    @other_races = Race.for_regatta(@regatta).joins(:results).nearby
    @measurements = @measuring.measurements
    @measurements_history = @measuring.measurement_set.measurements_history
    render :show
  end

  def save
    @res = @measuring.save!(params[:participants], params[:times])
  end

end