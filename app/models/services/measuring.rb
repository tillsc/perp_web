module Services
  class Measuring

    attr_reader :measurement_set
    attr_reader :race
    attr_reader :all_participants

    def initialize(race, measuring_point, force_measuring_session_ownership = nil)
      @race = race
      @all_participants = race.event.participants
      @lanes = (@race.results.presence || @race.starts).
        select { |r| @all_participants.first { |p| p.id == r.participant_id }&.active? }.
        map { |r| r.lane_number && [r.participant_id, r.lane_number] }.
        compact.
        sort_by(&:second).
        to_h
      @measurement_set = MeasurementSet.
        create_with(measuring_session: force_measuring_session_ownership).
        find_or_initialize_by(
          race: race,
          regatta: race.regatta,
          measuring_point: measuring_point
        )
      if (@measurement_set.measuring_point.id != measuring_point.id)
        @measurement_set.measuring_point = measuring_point
        @measurement_set.save!
      end
      if force_measuring_session_ownership && force_measuring_session_ownership.id != @measurement_set.measuring_session_id
        raise "Editing not allowed. This race is already handled by Session #{@measurement_set.measuring_session&.identifier.inspect}"
      end
    end

    def self.ftime(datetime)
      datetime&.strftime("%H:%M:%S.%2N")
    end
    delegate :ftime, to: :class

    def lane_for(participant_or_participant_id)
      participant_id = if participant_or_participant_id.is_a?(Participant)
                         participant_or_participant_id.participant_id
                       else
                         participant_or_participant_id&.to_i
                       end
      @lanes[participant_id]
    end

    def find_participant(participant_id)
      all_participants.find { |p| p.participant_id == participant_id&.to_i }
    end

    # Returns Hash(Participant or negative Integer => Time)
    def measurements
      (@measurement_set.measurements || []).map do |p_id, time, _rel_time|
        [find_participant(p_id) || p_id, time]
      end.to_h
    end

    def other_active_participants
      (@lanes.keys - (@measurement_set.measurements || []).map(&:first)).map do |p_id|
        find_participant(p_id)
      end
    end

    def other_participants
      p_ids = @lanes.keys + (@measurement_set.measurements || []).map(&:first)
      all_participants.reject do |p|
        p_ids.include?(p.participant_id)
      end
    end

    def save!(raw_participant_ids, raw_times, persist_result)
      participants = Array.wrap(raw_participant_ids).map { |p_id|
        p_id = p_id.presence&.to_i
        all_participants.find { |p| p.participant_id == p_id }
      }

      ftimes, rel_ftimes = if race.event.measuring_point_type(@measurement_set.measuring_point) == :start
                             calc_start_time(raw_times, participants.length)
                           else
                             calc_times(raw_times, race.started_at)
                           end

      i = 0
      participant_ids = participants.map do |p|
        if p
          p.participant_id
        else
          i+=1
          -i
        end
      end
      while participant_ids.length < ftimes.length
        i+=1
        participant_ids.push(-i)
      end
      res = participant_ids.zip(ftimes, rel_ftimes)
      @measurement_set.measurements = res
      @measurement_set.measurements_history||= {}
      last_history_date = @measurement_set.measurements_history.keys.last
      if last_history_date.present? && @measurement_set.measurements_history[last_history_date] != res
        @measurement_set.measurements_history[DateTime.now] = res
      end
      @measurement_set.save!

      if persist_result
        persist_result!
      end

      res
    end

    protected

    def persist_result!
      if race.event.measuring_point_type(@measurement_set.measuring_point) == :start
        @measurement_set.measurements.each_with_index do |(participant_id, _start_time, _), lane_number|
          result = race.results.find { |res| res.participant_id == participant_id } ||
            race.results.build(participant_id: participant_id)
          result.lane_number = lane_number + 1
          result.save!
        end
        time = @measurement_set.measurements.first&.second
        race.started_at_time = time && DateTime.parse(time)
        race.save!
      else
        present_participant_ids = []
        @measurement_set.measurements.each do |participant_id, _time, rel_time|
          if participant_id.to_i > 0 && rel_time.present?
            result = race.results.find { |res| res.participant_id == participant_id } ||
              race.results.build(participant_id: participant_id, race: race)
            result.set_time_for(@measurement_set.measuring_point, rel_time).save!
            present_participant_ids << participant_id
          end
        end
        # Delete all times which might be present from times before
        race.results.
          select { |res| !present_participant_ids.include?(res.participant_id)  }.
          map { |res| res.destroy_time_for!(@measurement_set.measuring_point) }
      end
    end

    def sanitize_times(raw_times)
      start_date = race.started_at || DateTime.now
      Array.wrap(raw_times).map { |t| Time.zone.parse(t).change(year: start_date.year, month: start_date.month, day: start_date.day) }
    end

    def calc_start_time(raw_times, participant_count)
      times = sanitize_times(raw_times)
      while times.any? && times.length < participant_count
        times.push(times.first)
      end
      [times, []]
    end

    def calc_times(raw_times, start_time)
      times = sanitize_times(raw_times)
      ftimes = times.map { |t| self.ftime(t) }
      rel_ftimes = start_time && times.map { |t| self.ftime(Time.at(t - start_time.to_time ).utc) } || []
      [ftimes, rel_ftimes]
    end

  end
end