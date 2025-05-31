module Services
  class StartlistGenerator

    attr_reader :errors

    def initialize(regatta, event, options)
      @regatta = regatta
      @event = event
      @options = options
      @errors = ActiveModel::Errors.new(self)
    end

    def generate_for(race_type)
      all_participants = @event.participants.enabled.to_a

      participants = case race_type
                     when 'V', 'A'
                       StartlistGenerator.participants_from_equal_distribution(
                         all_participants,
                         StartlistGenerator.number_of_heats(@regatta.number_of_lanes, all_participants.size))
                     when 'F'
                       participants_from_results(
                         all_participants, @regatta.number_of_lanes,
                         @event.results.preload(:times).by_type_short("V"),
                         @event.finish_measuring_point)
                     when 'K'
                       final_participant_ids = @event.starts.by_type_short("F").map(&:participant_id)
                       results = @event.results.preload(:times).
                         by_type_short("V").
                         to_a.
                         reject { |r| final_participant_ids.include?(r.participant_id) }
                       participants_from_results(
                         all_participants, @regatta.number_of_lanes,
                         results,
                         @event.finish_measuring_point)
                     else
                       @errors.add(:base, "Unsupported race type: #{race_type}")
                       nil
                     end

      if participants
        build_races_from_array(race_type, participants)
      else
        @event.races.by_type_short(race_type)
      end
    end

    def build_races_from_array(race_type, participants_per_race)
      races = @event.races.
        preload(starts: { participant: [:team, *Participant::ALL_ROWERS] }).
        by_type_short(race_type).order(:number).to_a
      participants_per_race.each_with_index do |participants, i|
        race = (races[i]||= @event.races.build(number: "#{race_type}#{i+1}")) # i+1 isn't the right thing to do
        race.starts.reset # Reset association but do not save
        participants.each_with_index do |participant, j|
          s = race.starts.build(participant: participant, lane_number: j + 1)
          if !s.valid?
            @errors.merge!(s.errors)
          end
        end
        if !race.valid?
          @errors.merge!(race.errors)
        end
      end
      while races.size > participants_per_race.size do
        races.pop
      end
      races
    end

    def participants_from_results(participants, number_of_lanes, results, finish_measuring_point)
      if results.none?
        if  participants.size <= number_of_lanes
          return [participants]
        else
          @errors.add(:base, "No results found to base the final on")
          return nil
        end
      else
        data = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
        results.sort_by { |r| r.sort_time_for(finish_measuring_point) }.each do |result|
          last_pos = data[result.race_number].keys.sort.last
          next_pos = last_pos.to_i + (last_pos && data[result.race_number][last_pos].size || 1).to_i
          if last_pos && data[result.race_number][last_pos].last&.time_for(finish_measuring_point) == result.time_for(finish_measuring_point)
            data[result.race_number][last_pos] += [result]
          else
            data[result.race_number][next_pos] += [result]
          end
        end
        ordered_participants = []
        rank = 1
        loop do
          next_participants = data.flat_map { |_race_num, results| Array.wrap(results[rank]).map(&:participant)  }
          break if next_participants.empty?
          break if ordered_participants.size + next_participants.size > number_of_lanes
          ordered_participants += next_participants
          rank += 1
        end

        [StartlistGenerator.reorder_participants(ordered_participants, @options[:placement_strategy])]
      end
    end

    # *** Side effect free functions ***

    def self.number_of_heats(number_of_lanes, number_of_teams)
      return 0 if number_of_teams <= 0

      # Step 1: All valid heat counts that divide evenly into lane count
      valid_heat_counts = (1..number_of_lanes).select { |n| number_of_lanes % n == 0 }

      # Step 2: From those, find the smallest heat count where all teams fit
      valid_heat_counts.each do |heats|
        if number_of_teams <= heats * number_of_lanes
          return heats
        end
      end

      # Step 3: Fallback – use max possible (still respecting final logic)
      number_of_lanes
    end

    def self.participants_from_equal_distribution(participants, number_of_heats)
      base_size = participants.size / number_of_heats
      remainder = participants.size % number_of_heats

      races = []
      index = 0
      number_of_heats.times do |i|
        size = base_size + (i < remainder ? 1 : 0)
        races << participants[index, size]
        index += size
      end
      races
    end

    def self.reorder_participants(participants, placement_strategy)
      case placement_strategy
      when 'start_at_lane_1'
        participants
      when 'end_at_lane_1'
        participants.reverse
      else
        participants.each_with_index.inject([]) do |res, (participant, i)|
          position = (participants.size / 2.0).ceil - 1 + (i.even? ? -i/2 : (i+1)/2)
          res.fill(participant, position, 1)
        end
      end
    end

  end
end