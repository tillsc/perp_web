class RegattaController < ApplicationController

  def show
    @events = @regatta.events.
        with_counts.
        includes(:participants)
    @latest_races = Race.
        with_results.
        for_regatta(@regatta).
        latest.
        limit(10)
    @next_races = Race.
        with_starts.
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

  def all_results
    @results = {}
    @regatta.results.preload(:times, race: {event: [:start_measuring_point, :finish_measuring_point]}, participant: [:team] + Participant::ALL_ROWERS).each do |result|
      @results[result.race.event]||= {}
      @results[result.race.event][result.race]||= []
      @results[result.race.event][result.race].push(result)
    end
    respond_to do |format|
      format.xml
    end
  end

  def upcoming
    @next_races = Race.
        joins(:starts).
        group('laeufe.Rennen, laeufe.Lauf').
        for_regatta(@regatta).
        upcoming
  end

  def representative
    @representative = Address.representative.
      find_by!(public_private_id: params[:public_private_id])

    @teams = (@regatta.teams.merge(@representative.teams)).preload(:participants)
  end  

end
