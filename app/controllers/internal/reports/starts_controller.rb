module Internal
  module Reports
    class StartsController < ApplicationController
      is_internal!

      before_action :load_race_types

      def index
        authorize! :index, Start

        @races = @regatta.races.
          joins(:starts).
          event_number_range(from: params[:event_number_from], to: params[:event_number_to]).
          then { |r| params[:race_types].present? ? r.by_type_short(params[:race_types]) : r }.
          order_by_planned_for.
          distinct.
          preload(:event, starts: { participant: [:team] + Participant::ALL_ROWERS })

        @races = @races.planned_from(Time.zone.parse(params[:planned_for_from])) if params[:planned_for_from].present?
        @races = @races.planned_until(Time.zone.parse(params[:planned_for_to])) if params[:planned_for_to].present?

        render layout: 'print'
      end

      private

      def load_race_types
        @race_types = Race.for_regatta(@regatta).map(&:type_short).uniq.sort_by(&Parameter.race_sorter)
      end
    end
  end
end
