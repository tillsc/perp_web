class MeasuringSessionsController < ApplicationController

  is_internal!
  def index
    authorize! :index, MeasuringSession

    @measuring_sessions = MeasuringSession.
      for_regatta(@regatta).
      with_stats.
      preload(:measuring_point, :active_measuring_point)
  end

  def show
    @measuring_session = MeasuringSession.for_regatta(@regatta).
      preload(:active_measuring_point, :measuring_point).
      find_by!(identifier: params[:id])
    authorize! :show, @measuring_session

    if cookies[:last_measuring_session_identifier] != @measuring_session.identifier
      cookies[:last_measuring_session_identifier] = @measuring_session.identifier
    end

    if @measuring_session.active_measuring_point
      races = Race.for_regatta(@regatta).
        preload(event: [:start_measuring_point, :finish_measuring_point], measurement_sets: :measuring_session).
        order(:planned_for).
        group_by{ |r|
          !r.measurement_set_for(@measuring_session.active_measuring_point)&.locked_for?(@measuring_session) &&
            r.event.measuring_point_type(@measuring_session.measuring_point_number).present?
        }

      @my_races = races[true]
      @other_races = races[false]
    end
  end

  def new
    if cookies[:last_measuring_session_identifier].present?
      ms = MeasuringSession.find_by(identifier: cookies[:last_measuring_session_identifier])
      @last_measuring_session = ms if ms&.regatta&.id == @regatta.id
    end

    @measuring_session = MeasuringSession.new(device_description: @last_measuring_session&.device_description, measuring_point_number: params[:measuring_point_number])
    authorize! :create, @measuring_session

    prepare_form
  end

  def create
    @measuring_session = MeasuringSession.new(measuring_session_params)
    authorize! :create, @measuring_session

    @measuring_session.regatta = @regatta
    if @measuring_session.save
      flash[:info] = helpers.success_message_for(:create, @measuring_session)
      redirect_to current_user.is_a?(MeasuringSession) ?
                    measuring_session_url(@regatta, @measuring_session) :
                    measuring_sessions_url(@regatta)
    else
      flash[:danger] = helpers.error_message_for(create, @measuring_session)
      prepare_form
      render :new
    end
  end

  def edit
    @measuring_session = MeasuringSession.for_regatta(@regatta).find_by!(identifier: params[:id])
    authorize! :update, @measuring_session

    prepare_form
  end

  def update
    @measuring_session = MeasuringSession.for_regatta(@regatta).find_by!(identifier: params[:id])

    if params[:activate].present?
      authorize! :activate, @measuring_session

      @measuring_session.measuring_point.update!(measuring_session: @measuring_session)
      flash[:info] = "Mess-Sitzung wurde aktiviert"

      redirect_to measuring_sessions_url(@regatta)
    elsif params[:deactivate].present?
      authorize! :deactivate, @measuring_session

      @measuring_session.measuring_point.update!(measuring_session: nil)
      flash[:info] = "Mess-Sitzung wurde deaktiviert"

      redirect_to measuring_sessions_url(@regatta)
    else
      authorize! :update, @measuring_session

      if @measuring_session.update(measuring_session_params)
        was_active_for_mp = MeasuringPoint.find_by(measuring_session: @measuring_session)
        if (was_active_for_mp && was_active_for_mp.id != @measuring_session.measuring_point.id)
          was_active_for_mp.update!(measuring_session: nil)
        end
        flash[:info] = helpers.success_message_for(:update, @measuring_session)
        redirect_to current_user.is_a?(MeasuringSession) ?
                      measuring_session_url(@regatta, @measuring_session) :
                      measuring_sessions_url(@regatta)
      else
        flash[:danger] = helpers.error_message_for(:update, @measuring_session)
        prepare_form
        render :edit
      end
    end
  end

  def destroy
    measuring_session = MeasuringSession.for_regatta(@regatta).find_by!(identifier: params[:id])
    authorize! :destroy, measuring_session

    measuring_session.destroy!

    flash[:info] = helpers.success_message_for(:destroy, measuring_session)
    redirect_to measuring_sessions_url(@regatta)
  end

  protected

  def prepare_form
    @measuring_points = MeasuringPoint.for_regatta(@regatta)
  end

  def measuring_session_params
    params.require(:measuring_session).permit(:device_description, :measuring_point_number, :autoreload_disabled, :hide_team_names)
  end

end