class AnnouncerController < ApplicationController

  def index
    @latest_races = Race.with_results.for_regatta(@regatta).latest.limit(10)
    @next_races = Race.for_regatta(@regatta).upcoming.limit(10)
  end

  def results
    @race = Race.
      for_regatta(@regatta).
      preload(results: :times, event: { participants: [:team] + Participant::ALL_ROWERS }).
      find_by(event_number: params[:event_number], number: params[:race_number])

    @previous_race = Race.for_regatta(@regatta).before_race(@race).first
    @next_race = Race.for_regatta(@regatta).following_race(@race).first
    @current_race = Race.for_regatta(@regatta).latest.first

    @measuring_points = MeasuringPoint.where(regatta_id: params[:regatta_id]).for_event(@race.event)
  end

end
