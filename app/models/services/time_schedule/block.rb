module Services
  class TimeSchedule
    class Block
      include ActiveModel::Model

      attr_reader :races

      def initialize(races, service)
        @races = Array.wrap(races)
        @service = service
      end

      def fits?(race)
        if !@service.special_race_type_treatment_for.include?(race.type_short)
          last_race = races.last

          return false if race.type_short != last_race.type_short
          return false if race.planned_for > last_race.planned_for + 15.minutes
          return false if race.event_number < last_race.event_number

          event_numbers_between = ((last_race.event_number + 1)..(race.event_number - 1)).to_a
          return false if event_numbers_between.intersect?(@service.event_numbers_with_race_type(race.type_short))

          last_time_span = races[-2] && (last_race.planned_for - races[-2].planned_for)
          current_time_span = race.planned_for - last_race.planned_for
          return false if last_time_span && current_time_span != last_time_span

          true
        else # special race treatment for things like "Kleines Finale" with jsut has to fit into the outer time bounds
          self.first_race_start <= race.planned_for &&
            self.last_race_end >= race.planned_for
        end
      end

      def title
        race_types = races.map(&:type_short).uniq
        "Rennen: #{ApplicationHelper.summarize_ranges(races.map(&:event_number).uniq.sort)}:
          #{race_types.map { |rt| Parameter.race_type_name(rt, pluralize: true)}.join(", ")}"
      end

      def id
        race_ids.to_s.hash
      end

      def race_ids
        races.map(&:id).sort
      end

      def first_race_start
        races.map(&:planned_for).min
      end

      def last_race_end
        races.map(&:planned_for).max + @service.default_race_duration
      end

      def to_event_data
        { id: id,
          title: title,
          start: first_race_start.iso8601,
          end: last_race_end.iso8601
        }
      end

      def set_first_start(new_first_start)
        new_first_start = Time.parse(new_first_start) if new_first_start.is_a?(String)

        delta = new_first_start - self.first_race_start
        self.races.each do |race|
          race.planned_for += delta
          race.save!
        end
      end
    end
  end
end
