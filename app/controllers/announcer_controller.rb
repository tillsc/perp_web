class AnnouncerController < ApplicationController

  is_internal!

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

    @previous_race = Race.for_regatta(@regatta).preload(:event).before_race(@race).first
    @next_race = Race.for_regatta(@regatta).preload(:event).following_race(@race).first
    @current_race = Race.for_regatta(@regatta).preload(:event).latest.first

    if @race.results.any?
      @measuring_points = MeasuringPoint.where(regatta_id: params[:regatta_id]).for_event(@race.event)
      @max_measuring_point_number = @race.results.map { |r| r.times.map(&:measuring_point_number).max }.compact.max
      @result_entries = build_result_entries(@race.results, @max_measuring_point_number)
    end
  end

  private

  def build_result_entries(results, measuring_point_number)
    participants = @race.event.participants.index_by(&:participant_id)
    current_rank = nil
    results = results.sort_by { |r| r.sort_time_for(measuring_point_number) }

    results.map.with_index do |r, i|
      result_time = r.time_for(measuring_point_number)
      previous_result_time = results[i - 1].time_for(measuring_point_number) if i > 0
      if result_time&.time != previous_result_time&.time
        current_rank = i + 1
      end

      { result: r,
        participant: participants[r.participant_id],
        lane: r.lane_number,
        rank: result_time.present? ? current_rank : nil,
        time: result_time&.time,
        diff_to_first: (result_time && i > 0) ? result_time.subtract_time(results[0].time_for(measuring_point_number)) : nil,
        diff_to_prev: previous_result_time && result_time.subtract_time(previous_result_time)
      }
    end
  end

end
