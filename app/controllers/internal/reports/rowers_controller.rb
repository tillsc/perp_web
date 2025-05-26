module Internal
  module Reports
    class RowersController < ApplicationController
      is_internal!

      def index
        authorize! :index, Rower

        @participants = @regatta.participants.joins(:event).preload(Participant::ALL_ROWERS_WITH_CLUBS)
        if params[:event_number_from].present?
          @participants = @participants.merge(Event.from_number(params[:event_number_from]))
        end
        if params[:event_number_to].present?
          @participants = @participants.merge(Event.to_number(params[:event_number_to]))
        end
        @rowers = @participants.inject({}) do |hash, participant|
          Participant::ALL_ROWERS.each do |rel|
            if rower = participant.send(rel)
              next if rower.last_name == "N.N."
              hash[rower]||= []
              hash[rower] << participant
            end
          end
          hash
        end
        @rowers = @rowers.sort_by { |r, _p| [r.last_name, r.first_name, r.year_of_birth.to_s] }
      end
    end
  end
end