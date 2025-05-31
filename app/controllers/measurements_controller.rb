class MeasurementsController < ApplicationController

  before_action except: [:index, :finish, :print] do
    @measuring_session = MeasuringSession.for_regatta(@regatta).
      preload(:measuring_point, :active_measuring_point).
      find_by(identifier: params[:measuring_session_id])

    @measuring_point = if can?(:manage, MeasurementSet) && params[:measuring_point_number].present?
                         @regatta.measuring_points.find_by!(number: params[:measuring_point_number])
                       else
                         @measuring_session&.active_measuring_point
                       end
    raise(ActionController::RoutingError, "Could not find valid MeasuringPoint!") unless @measuring_point

    ev = @regatta.events.find_by!(number: params[:event_number])
    preload_participants = if ev.measuring_point_type(@measuring_point) == :start
                             [:team, rowers: :weights]
                           else
                             :team
                           end

    @race = Race.
      for_regatta(@regatta).
      preload(:regatta, :starts, results: :times, event: [participants: preload_participants]).
      find_by!(event_number: params[:event_number], number: params[:race_number])

    @measuring = Services::Measuring.new(@race, @measuring_point, @measuring_session)
  end

  before_action only: [:finish_cam, :show] do
    if @race.event.measuring_point_type(@measuring_point) == :finish
      last_race = @regatta.races.latest.where.not(referee_starter_id: nil).first
      if last_race&.started_at && last_race.started_at > 20.minutes.ago
        @measuring.measurement_set.referee_starter_id||= last_race.referee_starter_id
        @measuring.measurement_set.referee_aligner_id||= last_race.referee_aligner_id
        @measuring.measurement_set.referee_finish_judge_id||= last_race.referee_finish_judge_id
      end
    end
  end

  def index
    authorize! :index, MeasurementSet

    @races = Race.for_regatta(@regatta).preload(:event)
    if params[:sort_by] == "start_time"
      @races = @races.order(:planned_for)
    end
    if params[:filter] == "today"
      @races = @races.planned_for_today
    elsif params[:filter] == "nearby"
      @races = @races.nearby
    end
    @measuring_points = MeasuringPoint.for_regatta(@regatta)
    @measurement_sets = MeasurementSet.for_regatta(@regatta).preload(:measuring_point, race: :event)
  end

  def finish
    authorize! :finish, MeasurementSet

    @race = @regatta.races.
      # preload(:referee_starter, :referee_aligner, :referee_umpire, :referee_finish_judge, results: [:times, participant: :team]).
      find_by!(event_number: params[:event_number], number: params[:race_number])
  end

  def print
    authorize! :print, MeasurementSet

    @race = @regatta.races.
      preload(:referee_starter, :referee_aligner, :referee_umpire, :referee_finish_judge, results: [:times, participant: :team]).
      find_by!(event_number: params[:event_number], number: params[:race_number])

    render layout: 'minimal'
  end

  def show
    authorize! :create, @measuring.measurement_set

    @measurements = @measuring.measurements
    @measurements_history = @measuring.measurement_set.measurements_history
    @measuring_session = @measuring.measurement_set.measuring_session
    @no_main_nav = current_user.is_a?(MeasuringSession)

    render :show
  end

  def save
    authorize! :create, @measuring.measurement_set
    autosave = params[:autosave] == "1"

    if !autosave && @measuring.is_start? && !params[:alternative_selected]
      times = Array.wrap(params[:times]).uniq
      if times.length < 2
        @original_time = times.first
        @alternative_times = @measuring.alternative_times_for(@original_time)
        if @alternative_times.any?
          render :select_alternative_time
          return
        end
      end
    end

    MeasuringSession.transaction do
      @res = if (params[:participant_times]) # finish cam
               @measuring.save_finish_cam!(params[:participant_times].permit!.to_h, true, measurement_set_params)
             else
               @measuring.save!(params[:participants], params[:times], true, measurement_set_params)
             end
    end

    if autosave
      redirect_to measurement_path(@regatta, race_number: @race.number, event_number: @race.event.number,
                                   measuring_session_id: params[:measuring_session_id],
                                   measuring_point_number: params[:measuring_point_number])
    elsif current_user.is_a?(MeasuringSession)
      redirect_to measuring_session_url(@regatta, current_user, anchor: "race_#{@measuring.race.event.number}_#{@measuring.race.number}")
    else
      redirect_to back_or_default(measurements_url(@regatta, anchor: @measuring.race.to_anchor))
    end
  end

  def finish_cam
    authorize! :create, @measuring.measurement_set

    @measurements = @measuring.measurements
    @measuring_session = @measuring.measurement_set.measuring_session
    @no_main_nav = current_user.is_a?(MeasuringSession)
    @backup_mode = params[:backup].present?
    lanes = (1..(@regatta.number_of_lanes + (@regatta.show_extra_lane? ? 1 : 0))).to_a
    lanes = lanes.reverse if @regatta.lane_1_on_finish_camera_side?
    @lanes = lanes.inject({}) do |h, lane|
      h.merge(lane => @measuring.participant_for_lane(lane))
    end

    respond_to do |format|
      format.html do
        @page_container_suffix = "-fluid"
        render :finish_cam
      end
    end
  end

  protected

  def measurement_set_params
    params[:measurement_set]&.permit(:referee_starter_id, :referee_aligner_id,
                                     :referee_umpire_id, :referee_finish_judge_id,
                                     :finish_cam_metadata, :backup_finish_cam_metadata)
  end

end