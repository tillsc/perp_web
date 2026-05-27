module Internal
  module Reports
    class ParticipantsController < ApplicationController
      is_internal!

      def index
        authorize! :index, Participant

        events = @regatta.events.order(:number)
        events = events.number_range(from: params[:event_number_from], to: params[:event_number_to])

        participants_scope = @regatta.participants
          .joins(:event)
          .preload(Participant::ALL_ROWERS + [:team])
          .merge(events)

        participants_scope = participants_scope.enabled unless params[:with_withdrawn] == "1"
        participants_scope = participants_scope.where(late_entry: true) if params[:only_late_entries] == "1"

        loaded = participants_scope.to_a

        @events_with_participants = events.to_a.filter_map do |event|
          ps = loaded.select { |p| p.event_number == event.number }
          [event, ps] if ps.any?
        end

        render layout: 'print'
      end
    end
  end
end
