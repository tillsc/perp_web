module Services
  class Measuring

    attr_reader :measurement_set
    attr_reader :race
    attr_reader :all_participants
    attr_reader :lanes

    def initialize(race, measuring_point, force_measuring_session_ownership = nil)
      @race = race
      @all_participants = race.event.participants
      @lanes = (@race.results.any? { |r| r.lane_number.to_i > 0 } ? @race.results : @race.starts).
        map { |r| r.lane_number && [r.participant_id, r.lane_number] }.
        compact.
        sort_by(&:second).
        to_h
      @measurement_set = MeasurementSet.
        create_with(
          measuring_session: force_measuring_session_ownership,
          referee_starter_id: race.referee_starter_id,
          referee_aligner_id: race.referee_aligner_id,
          referee_umpire_id: race.referee_umpire_id,
          referee_finish_judge_id: race.referee_finish_judge_id
          ).
        preload(:measuring_point, measuring_session: [:active_measuring_point, :measuring_point]).
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

    def participant_for_lane(lane)
      find_participant(@lanes.invert[lane])
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

    def save!(raw_participant_ids, raw_times, publish_result, measurement_set_attributes = nil)
      participants = Array.wrap(raw_participant_ids).map { |p_id|
        p_id = p_id.presence&.to_i
        all_participants.find { |p| p.participant_id == p_id }
      }

      ftimes, rel_ftimes = if self.is_start?
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

      save_measurements_hash!(res, publish_result, measurement_set_attributes)
    end

    def save_finish_cam!(raw_participant_times, publish_result, measurement_set_attributes = nil)
      res = raw_participant_times.map do |raw_participant_id, raw_time|
        raw_participant_id = raw_participant_id.presence&.to_i
        participant = all_participants.find { |p| p.participant_id == raw_participant_id }
        ftimes, rel_ftimes = calc_times([raw_time.presence].compact, race.started_at)
        [participant&.participant_id || raw_participant_id, ftimes.first, rel_ftimes.first]
      end.
        sort_by { |p_id, time, _rel_time| time.presence || "ZZZZZZZZZZZZ#{p_id}" }.
        reject { |p_id, time, _rel_time| p_id.to_i < 0 && time.nil? }

      save_measurements_hash!(res, publish_result, measurement_set_attributes)
    end

    def alternative_times_for(original_time)
      original_time||= ftime(DateTime.now)
      ExternalMeasurement.
        for_measuring_point(measurement_set.measuring_point).
        around(sanitize_times(original_time).first).
        map { |et| ftime(et.time) } - [original_time]
    end

    def is_start?
      race.event.measuring_point_type(@measurement_set.measuring_point) == :start
    end

    protected

    def save_measurements_hash!(measurements_hash, publish_result, measurement_set_attributes)
      if measurement_set_attributes.present?
        @measurement_set.attributes = measurement_set_attributes
      end
      @measurement_set.measurements = measurements_hash
      @measurement_set.measurements_history||= {}
      last_history_date = @measurement_set.measurements_history.keys.last
      history_entry = measurements_hash.map { |a| a.map(&:as_json) }
      if last_history_date.blank? || @measurement_set.measurements_history[last_history_date] != history_entry
        @measurement_set.measurements_history[DateTime.now] = history_entry
      end
      @measurement_set.save!

      if publish_result
        publish_result!
      end

      measurements_hash
    end

    def publish_result!
      if self.is_start?
        race.results.each do |r|
          r.lane_number = nil
          r.save!
        end
        @measurement_set.measurements.each_with_index do |(participant_id, _start_time, _), lane_number|
          if participant_id >= 0
            result = race.results.find { |res| res.participant_id == participant_id } ||
              race.results.build(participant_id: participant_id)
            result.lane_number = lane_number + 1
            result.save!
          end
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
        if race.event.measuring_point_type(@measurement_set.measuring_point) == :finish
          race.referee_starter_id = @measurement_set.referee_starter_id
          race.referee_aligner_id = @measurement_set.referee_aligner_id
          race.referee_umpire_id = @measurement_set.referee_umpire_id
          race.referee_finish_judge_id = @measurement_set.referee_finish_judge_id
          race.save!
        end
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