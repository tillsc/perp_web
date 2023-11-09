module Internal
  class EventsController < ApplicationController

    def index
      @events = @regatta.events
    end

    def new
      @event = @regatta.events.new(event_params)
      @event.number = @regatta.events.maximum(:number).to_i + 1 if @event.number.to_i == 0
      authorize! :new, @event
      prepare_form
    end

    def create
      @event = @regatta.events.new(event_params)
      authorize! :create, @event

      if @event.save
        flash[:info] = 'Rennen angelegt'
        redirect_to internal_events_url(@regatta, anchor: "event#{@event.id}")
      else
        flash[:danger] = "Rennen konnte nicht angelegt werden:\n#{@event.errors.full_messages}"
        prepare_form
        render :new
      end
    end

    def edit
      @event = @regatta.events.find(params[:id])
      authorize! :edit, @event
      prepare_form
    end

    def update
      @event = @regatta.events.find(params[:id])
      authorize! :update, @event

      if @event.update(event_params)
        flash[:info] = 'Rennen aktualisiert'
        redirect_to internal_events_url(@regatta, anchor: "event_#{@event.id}")
      else
        flash[:danger] = "Rennen konnte nicht gespeichert werden:\n#{@event.errors.full_messages}"
        prepare_form
        render :edit
      end
    end

    def destroy
      event = @regatta.events.find(params[:id])
      authorize! :destroy, event

      if event.destroy
        flash[:info] = 'Rennen gelöscht'
      else
        flash[:danger] = "Rennen konnte nicht gelöscht:\n#{event.errors.full_messages}"
      end
      redirect_to internal_events_url(@regatta)
    end

    protected

    def prepare_form
      @measuring_points = @regatta.measuring_points
    end

    def event_params
      params.fetch(:event, {}).permit(:name)
    end

  end
end