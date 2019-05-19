class EventsController < ApplicationController

  def index
    @events = @regatta.events.select('rennen.*, COUNT(DISTINCT startlisten.tnr, startlisten.lauf) starts_count, COUNT(DISTINCT meldungen.tnr) participants_count').
        left_outer_joins(:starts, :participants).
        group('rennen.regatta_id, rennen.rennen')
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

end
