class RegattaController < ApplicationController

  def show
    unless @regatta
      redirect_to internal_regattas_url
      return
    end

    @events = @regatta.events.
      with_counts.
      includes(:participants).
      preload(:races)
    @latest_races = Race.
      with_results.
      for_regatta(@regatta).
      latest.
      limit(10)
    @next_races = Race.
      for_regatta(@regatta).
      upcoming.
      preload(:starts, :event).
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
    @event = @regatta.events.
      preload(:starts, :races, participants: [:team] + Participant::ALL_ROWERS).
      find([params[:regatta_id], params[:event_id]])

    @results = @event.results.preload(:times, :race)

    @missing = {not_at_start: {}, withdrawn: {}, disqualified: {}}
    @results.group_by { |r| r.race.type_short.upcase }.each do |race_type, results|
      seen_participant_ids = results.map(&:participant_id)
      not_started = if Parameter.race_types_with_implicit_start_list.include?(race_type) or @event.races.map(&:type_short).uniq == [race_type]
                      @event.participants
                    else
                      @event.starts.map { |s| s.race_type_short == race_type ? @event.participants.find { |p| p.participant_id == s.participant_id  } : nil }
                    end.compact.reject { |p| seen_participant_ids.include?(p.participant_id) }
      not_started.each do |p|
        (@missing[p.withdrawn? ? :withdrawn : (p.disqualified? ? :disqualified : :not_at_start)][race_type]||= []) << p
      end
    end

    @measuring_points = MeasuringPoint.where(regatta_id: params[:regatta_id]).for_event(@event)
  end

  def all_results
    @results = {}
    @regatta.results.preload(:times,
                             race: { event: [:start_measuring_point, :finish_measuring_point] },
                             participant: [:team, Participant::ALL_ROWERS_WITH_CLUBS]).each do |result|
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
      for_regatta(@regatta).
      upcoming.
      preload(:starts, :event)
  end

  def rower
    @rower = Rower.find(params[:rower_id])

    @starts = Start.for_regatta(@regatta).
      for_rower(@rower).
      preload(race: :event, participant: [:team] + Participant::ALL_ROWERS).
      joins(:race).
      reorder('SollStartZeit')

    @results = Result.for_regatta(@regatta).
      for_rower(@rower).
      preload(:times, race: {event: :finish_measuring_point}, participant: [:team] + Participant::ALL_ROWERS).
      joins(:race).
      reorder('IstStartZeit')
  end

end
