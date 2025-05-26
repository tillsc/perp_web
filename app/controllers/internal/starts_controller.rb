module Internal
  class StartsController < ApplicationController

    is_internal!

    before_action :load_event

    def index
      authorize! :index, Start
      @race_types = @event.races.map(&:type_short).uniq
      @starts = @event.starts.preload(:race, participant: [:team, *Participant::ALL_ROWERS]).
        group_by { |s| s.race&.type_short }

      @prev_event = @regatta.events.to_number(@event.number - 1).reorder(:number).last
      @next_event = @regatta.events.from_number(@event.number + 1).reorder(:number).first
    end

    def new
      authorize! :new, Start

      @race_type = params[:race_type]
      generator = Services::StartlistGenerator.new(@regatta, @event, {})
      @races = generator.generate_for(@race_type)
      @remaining_participants = @event.participants - @races.flat_map { |r| r.starts.map(&:participant) }
      if generator.errors.any?
        flash.now[:danger] = "Automatische Startlistengenerierung fehlgeschlagen:<br>#{generator.errors.full_messages.join("<br>")}"
      end
    end

    def edit
      authorize! :edit, Start

      @race_type = params[:race_type]
      @races = @event.races.by_type_short(@race_type).preload(starts: { participant: [:team, *Participant::ALL_ROWERS] })
      participant_ids = @races.flat_map { |r| r.starts.map(&:participant_id) }
      @remaining_participants = @event.participants.preload(:team).reject { |p| participant_ids.include?(p.participant_id) }
    end

    def update
      authorize! :update, Start

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
          race = races.find { |r| r.number == race_number } ||
                 races.create!(number: race_number)
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
      @event = @regatta.events.preload(:races).find(params.extract_value(:event_id))
    end

    def default_url
      internal_event_starts_path(@regatta, @event, race_type: params[:race_type])
    end

  end
end