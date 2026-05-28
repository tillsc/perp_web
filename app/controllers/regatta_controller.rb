class RegattaController < ApplicationController

  before_action { @page_container_suffix = "-xxl" }

  def show
    unless @regatta
      redirect_to internal_regattas_url
      return
    end

    @events = @regatta.events.
      with_counts(:starts, :results).
      preload(:races, :participants)
    @latest_races = Race.
      with_results.
      for_regatta(@regatta).
      latest.
      preload(:event).
      limit(10)
    @next_races = Race.
      for_regatta(@regatta).
      upcoming.
      preload(:starts, :event).
      limit(10)
  end

  def participants
    @event = @regatta.events.where(number: params[:event_id]).
      preload(:races, participants: [:team] + Participant::ALL_ROWERS).
      first
  end

  def starts
    @event = Event.find([@regatta, params[:event_id]])
    @starts = @event.starts.
      joins(:race).
      preload(:race, participant: [:team] + Participant::ALL_ROWERS).
      order(:lane_number, :participant_id)
  end

  def results
    @event = Event.
      preload(:starts, :races, participants: [:team] + Participant::ALL_ROWERS).
      find([@regatta, params[:event_id]])

    @results = @event.results.preload(:times, race: [:referee_umpire, :referee_finish_judge])

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

    @measuring_points = MeasuringPoint.where(regatta: @regatta).for_event(@event)
  end

  def all_results
    authorize! :index, Result

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

  def time_schedule
    @races = Race.
      for_regatta(@regatta).
      preload(:event).
      order(:planned_for)
  end

  def participant
    @participant = @regatta.participants.
      where(event_number: params[:event_number], participant_id: params[:participant_id]).
      preload(:team, :event, Participant::ALL_ROWERS_WITH_CLUBS).
      first!

    @participant_results = @participant.results.
      preload(:times, race: [event: :finish_measuring_point]).
      joins(:race).unscope(:order).merge(Race.order_by_started_at).to_a

    @participant_starts = @participant.starts.
      preload(race: :event).
      joins(:race).unscope(:order).merge(Race.order_by_planned_for).to_a

    rowers = @participant.all_rowers
    data = results_and_starts_for(rowers.values)
    @rowers_data = rowers.transform_values do |rower|
      { rower: rower,
        results: data[rower.id][:results].reject { |r| r.participant_id == @participant.participant_id && r.event_number == @participant.event_number },
        starts:  data[rower.id][:starts].reject  { |s| s.participant_id == @participant.participant_id && s.event_number == @participant.event_number }
      }
    end
  end

  def rower
    @rower = Rower.preload(:club).find(params[:rower_id])
    data = results_and_starts_for([@rower])
    @results = data[@rower.id][:results]
    @starts  = data[@rower.id][:starts]
    @other_participants = @rower.participants.
      where.not(regatta_id: @regatta.id).
      preload(:regatta, :team, :event)
  end

  private

  def results_and_starts_for(rowers)
    all_results = Result.for_regatta(@regatta).for_rower(rowers).
      preload(:times, race: [event: :finish_measuring_point], participant: [:team] + Participant::ALL_ROWERS).
      joins(:race).unscope(:order).merge(Race.order_by_started_at).to_a

    all_starts = Start.for_regatta(@regatta).for_rower(rowers).
      preload(race: :event, participant: [:team] + Participant::ALL_ROWERS).
      joins(:race).unscope(:order).merge(Race.order_by_planned_for).to_a

    rowers.inject({}) do |h, rower|
      results = all_results.select { |r| Participant::ALL_ROWER_FIELD_NAMES.any? { |f| r.participant[f] == rower.id } }
      starts  = all_starts.select  { |s| Participant::ALL_ROWER_FIELD_NAMES.any? { |f| s.participant[f] == rower.id } }
      h.merge(rower.id => { results: results, starts: starts })
    end
  end

end
