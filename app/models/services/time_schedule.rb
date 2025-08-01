module Services
  class TimeSchedule

    include Enumerable
    delegate :each, to: :@blocks

    attr_reader :special_race_type_treatment_for, :default_race_duration

    def initialize(races, special_race_type_treatment_for: ['K'], default_race_duration: 8.minutes)
      @special_race_type_treatment_for = special_race_type_treatment_for
      @default_race_duration = default_race_duration

      @races = races
      @blocks = self.build_blocks(races)
    end

    def find(id = nil, &block)
      if id
        @blocks.find { |b| b.id == id }
      else
        @blocks.find(&block)
      end
    end

    def event_numbers_with_race_type(type_short)
      @_race_type_event_numbers||= @races.inject(Hash.new { |h, k| h[k] = [] }) do |h, race|
        h[race.type_short] += [race.event_number]
        h
      end
      @_race_type_event_numbers[type_short]
    end

    protected

    def build_blocks(races)
      normal_races, extra_races = races.
        select(&:planned_for).sort_by(&:planned_for).
        partition { |r| !@special_race_type_treatment_for.include?(r.type_short) }

      blocks = []
      normal_races.each do |race|
        if !blocks.last&.try_push_normal_race(race)
          blocks << TimeSchedule::Block.new(self, normal_race: race)
        end
      end

      extra_races.each do |race|
        if blocks.none? { |block| block.try_push_extra_race(race)}
          blocks << TimeSchedule::Block.new(self, extra_race: race)
        end
      end

      blocks
    end

  end
end