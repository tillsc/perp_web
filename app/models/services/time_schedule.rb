module Services
  class TimeSchedule

    include Enumerable
    delegate :each, to: :@blocks

    attr_reader :special_race_type_treatment_for, :default_race_duration

    def initialize(regatta, special_race_type_treatment_for: ['K'], default_race_duration: 8.minutes)
      @special_race_type_treatment_for = special_race_type_treatment_for
      @default_race_duration = default_race_duration

      @regatta = regatta
      @races = regatta.races.preload(:event)
      @blocks = self.build_blocks(@races)
    end

    def generate_block(event_number_from, event_number_to,
                       race_type, first_race_letter,
                       first_start, race_interval,
                       fixed_race_count)
      block = nil
      new_race_count = 0

      events = @regatta.events.
        from_number(event_number_from).to_number(event_number_to).
        with_counts(:participants) { |join_conditions, target_table| join_conditions.and(target_table[:withdrawn].eq(false).or(target_table[:withdrawn].eq(nil))) }

      raise "Keine Rennen im Bereich #{event_number_from} bis #{event_number_to} gefunden" unless events.any?

      events.each do |event|
        race_count = fixed_race_count
        if !race_count
          race_count = StartlistGenerator.number_of_heats(@regatta.number_of_lanes, event.participants_count)
        end

        race_count.times do |i|
          race_number = "#{race_type}#{(first_race_letter.ord + i).chr}"
          race = event.races.find_or_initialize_by(number: race_number)
          if race.persisted? && race.planned_for.present?
            raise "#{race.full_name} ist bereits terminiert für #{I18n.l(race.planned_for)}"
          end
          race.planned_for = first_start + (new_race_count * race_interval)
          if block
            block.try_push_normal_race(race) || raise("This should never happen: #{race.attributes.inspect}")
          else
            block = TimeSchedule::Block.new(self, normal_race: race)
          end
          new_race_count+= 1
        end
      end

      block
    end

    def find(id = nil, &block)
      if id
        res = @blocks.find { |b| b.id == id }
        if !res
          raise ActiveRecord::RecordNotFound.new("Couldn't find block with id #{id.inspect}")
        end
        res
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