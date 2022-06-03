class MeasuringSessionsController < ApplicationController

  def index
    raise "Not allowed" unless params[:fixme] == '1'

    @measuring_sessions = MeasuringSession.for_regatta(@regatta)
  end

  def show
    @measuring_session = MeasuringSession.for_regatta(@regatta).find_by!(identifier: params[:id])

    if @measuring_session.active_measuring_point
      @races = Race.for_regatta(@regatta).
        for_measuring(@measuring_session).
        preload(:event)
    end
  end

  def new
    @measuring_session = MeasuringSession.new
    prepare_form
  end

  def create
    @measuring_session = MeasuringSession.new(measuring_session_params)
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

  protected

  def prepare_form
    @measuring_points = MeasuringPoint.for_regatta(@regatta)
  end

  def measuring_session_params
    params.require(:measuring_session).permit(:device_description, 'MesspunktNr')
  end

end