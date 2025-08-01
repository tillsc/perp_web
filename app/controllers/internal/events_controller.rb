module Internal
  class EventsController < ApplicationController

    is_internal!

    def index
      authorize! :index, Event

      @events = @regatta.events.preload(:start_measuring_point, :finish_measuring_point)
    end

    def show
      @event = @regatta.events.
        preload(:start_measuring_point, :finish_measuring_point, :races).
        find(params.extract_value(:id))
      authorize! :show, @event
    end

    def new
      copy_event = @regatta.events.find_by(number: params[:copy_event_number]) if params[:copy_event_number].present?
      copy_or_last_event = copy_event || Event.for_regatta(@regatta).last
      @event = @regatta.events.new(event_params(
                                     number: @regatta.events.maximum(:number).to_i + 1,

                                     divergent_regatta_name: copy_or_last_event&.divergent_regatta_name,
                                     entry_fee: copy_or_last_event&.entry_fee,
                                     maximum_average_rower_weight: copy_or_last_event&.maximum_average_rower_weight,
                                     maximum_rower_weight: copy_or_last_event&.maximum_rower_weight,
                                     minimum_cox_weight: copy_or_last_event&.minimum_cox_weight,
                                     start_measuring_point_number: copy_or_last_event&.start_measuring_point_number,
                                     finish_measuring_point_number: copy_or_last_event&.finish_measuring_point_number,
                                     additional_text_format: copy_or_last_event&.additional_text_format,

                                     name_short: copy_event&.name_short,
                                     name_de: copy_event&.name_de,
                                     name_en: copy_event&.name_en,
                                     rower_count: copy_event&.rower_count || 1,
                                     is_lightweight: copy_event&.is_lightweight,
                                     has_cox: copy_event&.has_cox,
                                     additional_text: copy_event&.additional_text))
      authorize! :new, @event
      prepare_form
    end

    def create
      @event = @regatta.events.new(event_params)
      authorize! :create, @event

      if @event.save
        flash[:info] = helpers.success_message_for(:create, @event)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:create, @event)
        prepare_form
        render :new
      end
    end

    def edit
      @event = @regatta.events.find(params.extract_value(:id))
      authorize! :edit, @event
      prepare_form
    end

    def update
      @event = @regatta.events.find(params.extract_value(:id))
      authorize! :update, @event

      if @event.update(event_params)
        flash[:info] = helpers.success_message_for(:update, @event)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @event)
        prepare_form
        render :edit
      end
    end

    def destroy
      event = @regatta.events.find(params.extract_value(:id))
      authorize! :destroy, event

      if event.destroy
        flash[:info] = helpers.success_message_for(:destroy, event)
      else
        flash[:danger] = helpers.error_message_for(:destroy, event)
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      internal_events_url(@regatta, anchor: @event && dom_id(@event))
    end

    def prepare_form
      @measuring_points = @regatta.measuring_points.preload([])
    end

    def event_params(default = {})
      params.fetch(:event, default).permit(:number, :name_short, :name_de, :name_en, :divergent_regatta_name,
                                           :start_measuring_point_number, :finish_measuring_point_number,
                                           :is_lightweight, :has_cox, :rower_count,
                                           :maximum_average_rower_weight, :maximum_rower_weight, :minimum_cox_weight,
                                           :entry_fee,
                                           :additional_text, :additional_text_format
      )
    end

  end
end