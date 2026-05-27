module Internal
  module Reports
    class RowersController < ApplicationController
      is_internal!

      def index
        authorize! :index, Rower

        @participants = @regatta.participants.joins(:event).preload(Participant::ALL_ROWERS_WITH_CLUBS)
        @participants = @participants.merge(Event.number_range(from: params[:event_number_from], to: params[:event_number_to]))
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