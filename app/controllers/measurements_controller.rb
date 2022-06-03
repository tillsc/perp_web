class MeasurementsController < ApplicationController

  before_action do
    @measuring_session = MeasuringSession.for_regatta(@regatta).find_by(identifier: params[:measuring_session_id])
    @measuring_point = if @measuring_session
                         @measuring_session.active_measuring_point
                       else
                         raise "Not allowed" unless params[:fixme] == '1'
                         @regatta.measuring_points.find_by!(number: params[:measuring_point_number])
                       end
    @race = Race.for_regatta(@regatta).find_by!(event_number: params[:event_number], number: params[:race_number])
  end

  def show
    @other_races = Race.for_regatta(@regatta).joins(:results).nearby
    render :show
  end

  def save
    participants = @race.event.participants.where(participant_id:  Array.wrap(params[:participants]))
    times = Array.wrap(params[:times]).map { |t| Time.parse(t).change(year: @race.started_at.year, month: @race.started_at.month, day: @race.started_at.day, offset: @race.started_at.offset)  }
    rel_times = times.map { |t| Time.at(@race.started_at.to_time - t) }
    @res = participants.map.zip(times, rel_times)
  end

end