class MeasurementsController < ApplicationController

  before_action except: :index do
    @measuring_session = MeasuringSession.for_regatta(@regatta).find_by(identifier: params[:measuring_session_id])
    @measuring_point = if @measuring_session
                         @measuring_session.active_measuring_point
                       else
                         @regatta.measuring_points.find_by!(number: params[:measuring_point_number])
                       end
    raise "Could not find valid MeasuringPoint!" unless @measuring_point
    @race = Race.
      for_regatta(@regatta).
      find_by!(event_number: params[:event_number], number: params[:race_number])
    @measuring = Services::Measuring.new(@race, @measuring_point, @measuring_session)
  end

  def index
    authorize! :index, MeasurementSet

    @races = Race.for_regatta(@regatta)
    @measuring_points = MeasuringPoint.for_regatta(@regatta)
    @measurement_sets = MeasurementSet.for_regatta(@regatta).preload(:race, :measuring_point)
  end

  def show
    authorize! :create, @measuring.measurement_set

    @other_races = Race.for_regatta(@regatta).joins(:results).nearby
    @measurements = @measuring.measurements
    @measurements_history = @measuring.measurement_set.measurements_history
    @measuring_session = @measuring.measurement_set.measuring_session
    render :show
  end

  def save
    authorize! :create, @measuring.measurement_set

    MeasuringSession.transaction do
      @res = @measuring.save!(params[:participants], params[:times])
    end

    if current_user.is_a?(MeasuringSession)
      redirect_to measuring_session_url(@regatta, current_user, anchor: "race_#{@measuring.race.event.number}_#{@measuring.race.number}")
    else
      redirect_to measurements_url(@regatta, anchor: "race_#{@measuring.race.event.number}_#{@measuring.race.number}")
    end
  end

end