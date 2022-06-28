module Services
  class Measuring

    attr_reader :measurement_set
    attr_reader :race
    attr_reader :all_participants

    def initialize(measuring_session, race)
      @race = race
      @all_participants = race.event.participants
      @lanes = (@race.results.presence || @race.starts).
        sort_by(&:lane_number).
        map { |r| [r.participant_id, r.lane_number] }.
        to_h
      @measurement_set = MeasurementSet.find_or_initialize_for(measuring_session, race)
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

    def save!(raw_participant_ids, raw_times)
      participants = Array.wrap(raw_participant_ids).map { |p_id|
        p_id = p_id.presence&.to_i
        all_participants.find { |p| p.participant_id == p_id }
      }
      times = Array.wrap(raw_times).map { |t| Time.parse(t).change(year: race.started_at.year, month: race.started_at.month, day: race.started_at.day, offset: race.started_at.offset)  }
      ftimes = times.map { |t| self.ftime(t) }
      rel_ftimes = times.map { |t| self.ftime(Time.at(t - race.started_at.to_time )) }

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
      @measurement_set.measurements_history[DateTime.now] = res
      @measurement_set.save!

      res
    end

  end
end