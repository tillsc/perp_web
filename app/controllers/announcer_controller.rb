class AnnouncerController < ApplicationController

  is_internal!

  before_action { @page_container_suffix = "-xxl" }

  def index
    authorize! :access, :announcer_views

    @latest_races = Race.for_regatta(@regatta).
      with_results.latest.
      preload(:event).
      limit(10)
    @next_races = Race.for_regatta(@regatta).
      upcoming.
      preload(:event).
      limit(10)
  end

  def honors
    authorize! :access, :honors

    @races = Race.for_regatta(@regatta).pending_honor.
      preload(:event, results: [:times, { participant: [:team] + Participant::ALL_ROWERS }]).
      limit(3)
  end

  def honor
    race = Race.for_regatta(@regatta).find_by!(event_number: params[:event_number], number: params[:race_number])
    authorize! :honor, race
    race.update!(honored_at: Time.current)
    redirect_to back_or_default
  end

  def revoke_honor
    race = Race.for_regatta(@regatta).find_by!(event_number: params[:event_number], number: params[:race_number])
    authorize! :honor, race
    race.update!(honored_at: nil)
    redirect_to back_or_default
  end

  def results
    authorize! :access, :announcer_views

    @race = Race.
      for_regatta(@regatta).
      preload(:referee_umpire, :referee_finish_judge, :starts, results: :times, event: { participants: [:team] + Participant::ALL_ROWERS }).
      find_by(event_number: params[:event_number], number: params[:race_number])

    if !@race
      redirect_to announcer_url
      return
    end

    @pending_honors = Race.for_regatta(@regatta).pending_honor.exists?

    unless turbo_frame_request?
      @previous_race = Race.for_regatta(@regatta).preload(:event).before_race(@race).first
      @next_race = Race.for_regatta(@regatta).preload(:event).following_race(@race).first
      @current_race = Race.for_regatta(@regatta).preload(:event).latest.first
      @same_event_races = @race.event.races.where.not(number: @race.number).order(:number)
      @related_event_races = Race.for_regatta(@regatta).
        joins(:event).
        where(Event.arel_table[:name_short].eq(@race.event.name_short)).
        where.not(event_number: @race.event_number).
        preload(:event).
        order(:event_number, :number)
    end

    participants = @race.event.participants.index_by(&:participant_id)

    if @race.results.any?
      @measuring_points = MeasuringPoint.where(regatta_id: params[:regatta_id]).for_event(@race.event)
      @max_measuring_point_number = @race.results.map { |r| r.times.map(&:measuring_point_number).max }.compact.max
      current_rank = nil
      results = @race.results.sort_by { |r| r.sort_time_for(@max_measuring_point_number) }
      @result_entries = results.map.with_index do |r, i|
        result_time = r.time_for(@max_measuring_point_number)
        previous_result_time = results[i - 1].time_for(@max_measuring_point_number) if i > 0
        current_rank = i + 1 if result_time&.time != previous_result_time&.time
        { result: r, participant: participants[r.participant_id], lane: r.lane_number,
          rank: result_time.present? ? current_rank : nil,
          diff_to_prev: previous_result_time && result_time.subtract_time(previous_result_time) }
      end
    else
      @result_entries = @race.starts.sort_by(&:lane_number).map do |s|
        { participant: participants[s.participant_id], lane: s.lane_number }
      end
    end
  end

  protected

  def default_url
    if @race
      announcer_results_url(@regatta, @race.event_number, @race.number)
    else
      announcer_url(@regatta)
    end
  end

end
