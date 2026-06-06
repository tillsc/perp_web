module Internal
  module Reports
    class ResultsController < ApplicationController
      is_internal!

      before_action :load_race_types

      def index
        authorize! :index, Result

        @all_measuring_points = MeasuringPoint.where(regatta: @regatta).order(:number).to_a

        @races = @regatta.races.
          joins(:results).
          event_number_range(from: params[:event_number_from], to: params[:event_number_to]).
          then { |r| params[:race_types].present? ? r.by_type_short(params[:race_types]) : r }.
          order_by_event_number.
          order(Race.arel_table[:number].asc).
          distinct.
          preload(:referee_umpire, :referee_finish_judge,
                  event: [:start_measuring_point, :finish_measuring_point, :starts, :races,
                          { participants: [:team] + Participant::ALL_ROWERS }],
                  results: :times)

        render layout: 'print'
      end

      private

      def load_race_types
        @race_types = Race.for_regatta(@regatta).map(&:type_short).uniq.sort_by(&Parameter.race_sorter)
      end
    end
  end
end
