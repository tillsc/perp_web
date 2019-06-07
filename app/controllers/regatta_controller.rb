class RegattaController < ApplicationController

  def show
    @events = @regatta.events.with_counts
    @latest_races = Race.
        joins(:results).
        group('laeufe.Rennen, laeufe.Lauf').
        for_regatta(@regatta).
        latest.
        limit(10)
    @next_races = Race.
        joins(:starts).
        group('laeufe.Rennen, laeufe.Lauf').
        for_regatta(@regatta).
        upcoming.
        limit(10)
  end

  def participants
    @event = @regatta.events.where(regatta_id: params[:regatta_id], rennen: params[:event_id]).
        preload(participants: [:team] + Participant::ALL_ROWERS).
        first
  end

  def starts
    @event = @regatta.events.find([params[:regatta_id], params[:event_id]])
    @starts = @event.starts.preload(:race, participant: [:team] + Participant::ALL_ROWERS)
  end

  def results
    @event = @regatta.events.find([params[:regatta_id], params[:event_id]])
    @results = @event.results.preload(:race, :times, participant: [:team] + Participant::ALL_ROWERS)
    @measuring_points = MeasuringPoint.where(regatta_id: params[:regatta_id]).for_event(@event)
  end

end
