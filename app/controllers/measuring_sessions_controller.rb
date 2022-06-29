class MeasuringSessionsController < ApplicationController

  def index
    authorize! :index, MeasuringSession

    @measuring_sessions = MeasuringSession.for_regatta(@regatta)
  end

  def show
    @measuring_session = MeasuringSession.for_regatta(@regatta).find_by!(identifier: params[:id])
    authorize! :show, @measuring_session

    if @measuring_session.active_measuring_point
      @races = Race.for_regatta(@regatta).
        for_measuring(@measuring_session).
        preload(:event)
    end
  end

  def new
    @measuring_session = MeasuringSession.new
    authorize! :create, @measuring_session

    prepare_form
  end

  def create
    @measuring_session = MeasuringSession.new(measuring_session_params)
    authorize! :create, @measuring_session

    @measuring_session.regatta = @regatta
    if @measuring_session.save
      flash[:info] = 'Mess-Sitzung angelegt'
      redirect_to measuring_session_url(@regatta, @measuring_session)
    else
      flash[:danger] = "Mess-Sitzung konnte nicht angelegt werden:\n#{@measuring_session.errors.full_messages}"
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
    authorize! :update, @measuring_session

    if params[:activate].present?
      @measuring_session.measuring_point.update!(measuring_session: @measuring_session)
      flash[:info] = "Mess-Sitzung wurde aktiviert"

      redirect_to measuring_sessions_url(@regatta)
    elsif params[:deactivate].present?
      @measuring_session.measuring_point.update!(measuring_session: nil)
      flash[:info] = "Mess-Sitzung wurde deaktiviert"

      redirect_to measuring_sessions_url(@regatta)
    else
      if @measuring_session.update(measuring_session_params)
        flash[:info] = "Mess-Sitzung aktualisiert"
        redirect_to measuring_sessions_url(@regatta)
      else
        prepare_form
        render :edit
      end
    end

  end

  protected

  def prepare_form
    @measuring_points = MeasuringPoint.for_regatta(@regatta)
  end

  def measuring_session_params
    params.require(:measuring_session).permit(:device_description, 'MesspunktNr')
  end

end