module Services
  class StartlistGenerator

    attr_reader :errors

    def initialize(regatta, event, options)
      @regatta = regatta
      @event = event
      @participants = event.participants.enabled.to_a
      @options = options
      @errors = ActiveModel::Errors.new(self)
    end

    def generate_for(race_type)
      default_return_value = @event.races.by_type_short(race_type)
      case race_type
      when 'V', 'A'
        build_races_from_array(race_type, distribute_participants(number_of_heats(@participants.size)))
      when 'F'
        based_upon_race_results = @event.results.preload(:times).by_type_short("V")
        if based_upon_race_results.none?
          if  @participants.size <= @regatta.number_of_lanes
            build_races_from_array(race_type, [@participants])
          else
            @errors.add(:base, "No results found to base the final on")
            default_return_value
          end
        else
          data = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
          based_upon_race_results.sort_by { |r| r.sort_time_for(@event.finish_measuring_point) }.each do |result|
            last_pos = data[result.race_number].keys.sort.last
            next_pos = last_pos.to_i + (last_pos && data[result.race_number][last_pos].size || 1).to_i
            if last_pos && data[result.race_number][last_pos].last&.time_for(@event.finish_measuring_point) == result.time_for(@event.finish_measuring_point)
              data[result.race_number][last_pos] += [result]
            else
              data[result.race_number][next_pos] += [result]
            end
          end
          ordered_participants = []
          rank = 1
          loop do
            next_participants = data.flat_map { |_race_num, results| Array.wrap(results[rank]).map(&:participant)  }
            break if ordered_participants.size + next_participants.size > @regatta.number_of_lanes
            ordered_participants += next_participants
            rank += 1
          end
          ordered_participants = case @options[:placement_strategy]
                                 when 'start_at_lane_1'
                                   ordered_participants
                                 when 'end_at_lane_1'
                                   ordered_participants.reverse
                                 else
                                   ordered_participants.each_with_index.inject([]) do |res, (participant, i)|
                                     position = (ordered_participants.size / 2.0).ceil - 1 + (i.even? ? -i/2 : (i+1)/2)
                                     res.fill(participant, position, 1)
                                   end
                                 end
          build_races_from_array(race_type, [ordered_participants])
        end
      else
        @errors.add(:base, "Unsupported race type: #{race_type}")
        default_return_value
      end
    end

    protected

    def build_races_from_array(race_type, participants_per_race)
      races = @event.races.
        preload(starts: { participant: [:team, *Participant::ALL_ROWERS] }).
        by_type_short(race_type).order(:number).to_a
      participants_per_race.each_with_index do |participants, i|
        race = (races[i]||= @event.races.build(number: "#{race_type}#{i+1}")) # i+1 isn't the right thing to do
        race.starts.target.clear # Reset association but do not save
        participants.each_with_index do |participant, j|
          s = race.starts.build(participant: participant, lane_number: j + 1)
          if !s.valid?
            @errors = @errors.merge!(s.errors)
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

    def number_of_heats(number_of_teams)
      number_of_lanes = @regatta.number_of_lanes

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

    def distribute_participants(number_of_heats)
      base_size = @participants.size / number_of_heats
      remainder = @participants.size % number_of_heats

      races = []
      index = 0
      number_of_heats.times do |i|
        size = base_size + (i < remainder ? 1 : 0)
        races << @participants[index, size]
        index += size
      end

      races
    end


  end
end