class AnnouncerController < ApplicationController

  def index
    @latest_races = Race.for_regatta(@regatta).
      with_results.latest.
      preload(:event).
      limit(10)
    @next_races = Race.for_regatta(@regatta).
      upcoming.
      preload(:event).
      limit(10)
  end

  def results
    @race = Race.
      for_regatta(@regatta).
      preload(:referee_umpire, :referee_finish_judge, :starts, results: :times, event: { participants: [:team] + Participant::ALL_ROWERS }).
      find_by(event_number: params[:event_number], number: params[:race_number])

    @previous_race = Race.for_regatta(@regatta).preload(:event).before_race(@race).first
    @next_race = Race.for_regatta(@regatta).preload(:event).following_race(@race).first
    @current_race = Race.for_regatta(@regatta).preload(:event).latest.first

    @measuring_points = MeasuringPoint.where(regatta_id: params[:regatta_id]).for_event(@race.event)
  end

end
