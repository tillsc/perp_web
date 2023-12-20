module Internal
  class EventsController < ApplicationController

    def index
      @events = @regatta.events
    end

    def new
      last_event = @regatta.events.last
      @event = @regatta.events.new(event_params(
                                     number: @regatta.events.maximum(:number).to_i + 1,
                                     entry_fee: last_event&.entry_fee,
                                     rower_count: last_event&.rower_count || 1,
                                     maximum_average_weight: last_event&.maximum_average_weight,
                                     maximum_single_weight: last_event&.maximum_single_weight,
                                     maximum_cox_weight: last_event&.maximum_cox_weight,
                                     start_measuring_point_number: last_event&.start_measuring_point_number,
                                     finish_measuring_point_number: last_event&.finish_measuring_point_number,
                                     additional_text_format: last_event&.additional_text_format))
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
      @event = @regatta.events.find([params[:regatta_id], params[:id]])
      authorize! :edit, @event
      prepare_form
    end

    def update
      @event = @regatta.events.find([params[:regatta_id], params[:id]])
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
      event = @regatta.events.find([params[:regatta_id], params[:id]])
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

    def event_params(default = {})
      params.fetch(:event, default).permit(:number, :name_short, :name_de, :name_en, :divergent_regatta_name,
                                           :start_measuring_point_number, :finish_measuring_point_number,
                                           :is_lightweight, :has_cox, :rower_count,
                                           :maximum_average_weight, :maximum_single_weight, :maximum_cox_weight,
                                           :entry_fee,
                                           :additional_text, :additional_text_format
      )
    end

  end
end