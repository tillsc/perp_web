module Services
  class TimeSchedule
    class Block
      include ActiveModel::API

      attr_reader :normal_races, :extra_races

      def initialize(service, normal_race: nil, extra_race: nil)
        @service = service

        @normal_races = Array.wrap(normal_race)
        @extra_races = Array.wrap(extra_race)
        raise "A Block may never be empty" unless all_races.any?
      end

      def try_push_normal_race(race)
        if fits_as_normal_race?(race)
          @normal_races << race
          true
        else
          false
        end
      end

      def try_push_extra_race(race)
        if fits_as_extra_race?(race)
          @extra_races << race
          true
        else
          false
        end
      end

      def all_races
        @normal_races + @extra_races
      end

      def title
        race_types = all_races.map(&:type_short).uniq
        "Rennen: #{ApplicationHelper.summarize_ranges(all_races.map(&:event_number).uniq.sort)}:
          #{race_types.map { |rt| Parameter.race_type_name(rt, pluralize: true)}.join(", ")}"
      end

      def additional_info
        "#{(last_time_span / 60.0).to_i} Minuten Rennabstand" if last_time_span.present?
      end

      def time_span_matches?(next_race_planned_for)
        last = last_time_span
        last.nil? || (next_race_planned_for - self.normal_races[-1].planned_for) == last
      end

      def last_time_span
        self.normal_races[-2] && (self.normal_races[-1].planned_for - self.normal_races[-2].planned_for)
      end

      def id
        race_ids.to_s.hash
      end

      def race_ids
        all_races.map(&:id).sort
      end

      def first_race_start
        self.normal_races.map(&:planned_for).min
      end

      def last_race_start
        self.normal_races.map(&:planned_for).max
      end

      def last_race_end
        last_race_start + @service.default_race_duration
      end

      def to_event_data
        { id: id,
          title: title,
          start: first_race_start.iso8601,
          end: last_race_end.iso8601,
          extendedProps: {
            additionalInfo: additional_info
          }
        }
      end

      def intersects?(other_block)
        first_race_start < other_block.last_race_start &&
          other_block.last_race_start < last_race_end
      end

      def set_first_start(new_first_start)
        new_first_start = Time.parse(new_first_start) if new_first_start.is_a?(String)

        delta = new_first_start - self.first_race_start
        self.all_races.each do |race|
          race.planned_for += delta
        end
      end

      def insert_break(break_start, break_length)
        if break_start.is_a?(String)
          date = self.first_race_start.to_date
          break_start = Time.zone.parse("#{date} #{break_start}")
        end

        if break_start < self.first_race_start || break_start > self.last_race_start
          raise "Pause #{I18n.l(break_start)} liegt ausserhalb des Blocks von #{I18n.l(self.first_race_start)} bis #{I18n.l(self.last_race_start)}"
        end

        self.all_races.select { |r| r.planned_for >= break_start }.each do |race|
          race.planned_for += break_length.minutes
        end
      end

      def save!
        self.all_races.each(&:save!)
      end

      protected

      def fits_as_normal_race?(race)
        last_race = self.normal_races.last

        return false if race.type_short != last_race.type_short
        return false if race.planned_for > last_race.planned_for + 15.minutes
        return false if race.event_number < last_race.event_number

        event_numbers_between = ((last_race.event_number + 1)..(race.event_number - 1)).to_a
        return false if event_numbers_between.intersect?(@service.event_numbers_with_race_type(race.type_short))

        return false if !time_span_matches?(race.planned_for)

        true
      end

      def fits_as_extra_race?(race)
        self.first_race_start <= race.planned_for &&
          self.last_race_end >= race.planned_for
      end

    end
  end
end
