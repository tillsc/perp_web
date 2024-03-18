module Internal
  class ParticipantsController < ApplicationController

    is_internal!

    def index
      @participants = @regatta.participants.preload(:event, :team)
      if params[:event_number].present?
        @participants = @participants.where(event_number: params[:event_number])
      end
    end

    def new
      @participant = @regatta.participants.new(participant_params)

      authorize! :new, @participant
      prepare_form
    end

    def create
      @participant = @regatta.participants.new(participant_params)
      @participant.set_participant_id
      authorize! :create, @participant

      if @participant.event
        if @participant.save
          flash[:info] = 'Meldung angelegt'
          redirect_to back_or_default
        else
          flash[:danger] = "Meldung konnte nicht angelegt werden:\n#{@participant.errors.full_messages.join(', ')}"
          prepare_form
          render :new
        end
      else
        render :new
      end
    end

    def edit
      @participant = @regatta.participants.find(params.extract_value(:id))
      authorize! :edit, @participant
      prepare_form
    end

    def update
      @participant = @regatta.participants.find(params.extract_value(:id))
      authorize! :update, @participant

      if @participant.update(participant_params)
        flash[:info] = 'Meldung aktualisiert'
        redirect_to back_or_default
      else
        flash[:danger] = "Meldung konnte nicht gespeichert werden:\n#{@participant.errors.full_messages.join(', ')}"
        prepare_form
        render :edit
      end
    end

    def destroy
      participant = @regatta.participants.find(params.extract_value(:id))
      authorize! :destroy, participant

      if participant.destroy
        flash[:info] = 'Meldung gelöscht'
      else
        flash[:danger] = "Meldung konnte nicht gelöscht werden:\n#{participant.errors.full_messages.join(', ')}"
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      anchor = "participant_#{@participant.to_param}" if @participant
      internal_participants_url(@regatta, anchor: anchor)
    end

    def prepare_form
    end

    def participant_params(default = {})
      params.fetch(:participant, default).permit(:event_number, :team_id,  :number, :team_boat_number,
                                                 :withdrawn, :late_entry, :entry_changed, :disqualified,
                                                 :history, *Participant::ALL_ROWERS.map{ |field| "#{field}_id" })
    end

  end
end