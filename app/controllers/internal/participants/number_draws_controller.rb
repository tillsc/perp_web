module Internal
  module Participants
    class NumberDrawsController < ApplicationController

      is_internal!

      def new
        authorize! :update, Participant

        @sector_size = params.fetch(:sector_size, 2).to_i

        first_number = @regatta.events.order(:number).first&.number
        @event_number_from = params.fetch(:event_number_from, first_number).to_i
        @event_number_to   = params.fetch(:event_number_to,   first_number).to_i

        events = @regatta.events.order(:number)
          .where(number: @event_number_from..@event_number_to)

        service = Services::NumberDraw.new(sector_size: @sector_size)
        @proposals_by_event = events.index_with do |event|
          service.call(event.participants.enabled.preload(:team))
        end
      end

      def create
        authorize! :update, Participant

        Participant.transaction do
          params.fetch(:numbers, {}).each do |participant_key, number|
            next if number.blank?
            @regatta.participants
              .find(participant_key.split('_', -1))
              .update!(number: number.to_i)
          end
        end

        flash[:info] = "Bugnummern wurden gespeichert."
        redirect_to back_or_default
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
        flash[:danger] = "Fehler beim Speichern: #{e.message}"
        redirect_to new_internal_participants_number_draw_path(@regatta)
      end

      protected

      def default_url
        internal_participants_path(@regatta)
      end

    end
  end
end
