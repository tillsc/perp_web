module Internal
  class StartsController < ApplicationController

    is_internal!

    before_action :load_event

    def index
      @race_types = @event.races.map(&:type_short).uniq
      @starts = @event.starts.preload(:race, participant: :team).
        group_by { |s| s.race&.type_short }
    end

    def edit
      @race_type = params[:race_type]
      @races = @event.races.by_type_short(@race_type).preload(starts: { participant: :team })
      participant_ids = @races.flat_map { |r| r.starts.map(&:participant_id) }
      @remaining_participants = @event.participants.reject { |p| participant_ids.include?(p.participant_id) }
    end

    def save
      race_type = params[:race_type]
      races = @event.races.by_type_short(race_type)
      starts = params[:starts].
        slice_before { |e| e.present? && e !~ /^\d+$/ }.
        map { |sub_arr| [sub_arr.shift, sub_arr] }.
        to_h
      Start.transaction do
        # Delete old start list entries
        @event.starts.by_type_short(race_type).destroy_all
        starts.each do |race_number, st|
          race = races.find { |r| r.number == race_number } || raise("Couldn't find rafe for race_number #{race_number.inspect} in #{races}")
          st.each_with_index do |participant_id, i|
            if participant_id.present?
              race.starts.create!(lane_number: i + 1, participant_id: participant_id)
            end
          end
        end
      end
      redirect_to back_or_default
    end

    protected

    def load_event
      @event = @regatta.events.find(params.extract_value(:event_id))
    end

    def default_url
      internal_event_starts_path(@regatta, @event)
    end

  end
end