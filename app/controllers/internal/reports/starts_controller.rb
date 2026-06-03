module Internal
  module Reports
    class StartsController < ApplicationController
      is_internal!

      def index
        authorize! :index, Start

        events = @regatta.events.unscope(:order).
          number_range(from: params[:event_number_from], to: params[:event_number_to])

        @races = @regatta.races.
          joins(:event, :starts).
          merge(events).
          order_by_planned_for.
          distinct.
          preload(:event, starts: { participant: [:team] + Participant::ALL_ROWERS })

        @races = @races.planned_from(Time.zone.parse(params[:planned_for_from])) if params[:planned_for_from].present?
        @races = @races.planned_until(Time.zone.parse(params[:planned_for_to])) if params[:planned_for_to].present?

        render layout: 'print'
      end
    end
  end
end
