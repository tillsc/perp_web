module Internal
  module Reports
    class ResultsController < ApplicationController
      is_internal!

      def index
        authorize! :index, Result

        @all_measuring_points = MeasuringPoint.where(regatta: @regatta).order(:number).to_a

        events = @regatta.events.order(:number)
        events = events.from_number(params[:event_number_from]) if params[:event_number_from].present?
        events = events.to_number(params[:event_number_to]) if params[:event_number_to].present?

        @events_with_results = events
          .preload(:start_measuring_point, :finish_measuring_point,
                   participants: [:team] + Participant::ALL_ROWERS,
                   races: [:referee_umpire, :referee_finish_judge, { results: :times }])
          .reject { |e| e.races.all? { |r| r.results.empty? } }

        render layout: 'print'
      end
    end
  end
end
