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
      @participant_params = participant_params
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
          flash[:info] = helpers.success_message_for(:create, @participant)
          redirect_to back_or_default
        else
          flash[:danger] = helpers.error_message_for(:create, @participant)
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
        flash[:info] = helpers.success_message_for(:update, @participant)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @participant)
        prepare_form
        render :edit
      end
    end

    def destroy
      participant = @regatta.participants.find(params.extract_value(:id))
      authorize! :destroy, participant

      if participant.destroy
        flash[:info] = helpers.success_message_for(:destroy, participant)
      else
        flash[:danger] = helpers.error_message_for(:destroy, participant)
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      internal_participants_url(@regatta, anchor: @participant&.to_anchor)
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