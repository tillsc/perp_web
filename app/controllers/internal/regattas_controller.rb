module Internal
  class RegattasController < ApplicationController

    is_internal!

    def index
      authorize! :index, Regatta

      @regattas = Regatta.preload(:organizer, :events).order(from_date: :desc)
    end

    def new
      @regatta = Regatta.new(regatta_params)
      authorize! :new, @regatta

      prepare_form
    end

    def create
      @regatta = Regatta.new(regatta_params)
      authorize! :create, @regatta

      copy_from = Regatta.preload(:measuring_points, :events).find_by(id: @regatta.copy_events_from_regatta_id)

      if source_for_measuring_points = copy_from || Regatta.preload(:measuring_points).last
        @regatta.measuring_points = source_for_measuring_points.measuring_points.map do |mp|
          mp.dup.tap do |new_mp|
            new_mp.number = mp.number # dup resets this
          end
        end
      else
        (0..4).each do |mp_num|
          @regatta.measuring_points.build(number: mp_num, position: mp_num * 500)
        end
      end

      Regatta.transaction do
        if @regatta.save
          if copy_from
            copy_from.events.each do |event|
              new_event = event.dup
              new_event.regatta_id = @regatta.id
              new_event.number = event.number # dup resets composite PK
              new_event.save!
            end
          end
          flash[:info] = helpers.success_message_for(:create, @regatta)
          redirect_to back_or_default
        else
          flash[:danger] = helpers.error_message_for(:create, @regatta)
          prepare_form
          render :new, status: :unprocessable_entity
        end
      end
    end

    def edit
      @regatta = Regatta.find(params[:id])
      authorize! :edit, @regatta

      prepare_form
    end

    def update
      @regatta = Regatta.find(params[:id])
      authorize! :update, @regatta

      if @regatta.update(regatta_params)
        flash[:info] = helpers.success_message_for(:update, @regatta)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @regatta)
        prepare_form
        render :edit, status: :unprocessable_entity
      end
    end

    def activate
      @regatta = Regatta.find(params[:regatta_id])
      authorize! :activate, @regatta

      Parameter.set_value_for!('Global', 'AktRegatta', @regatta.id)

      flash[:info] = 'Regatta wurde als aktive Regatta gesetzt'
      redirect_to back_or_default
    end

    def destroy
      regatta = Regatta.find(params[:id])
      authorize! :destroy, regatta
      regatta.strict_loading!(false)

      if regatta.destroy
        flash[:info] = helpers.success_message_for(:destroy, regatta)
      else
        flash[:danger] = helpers.error_message_for(:destroy, regatta)
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      internal_regattas_url(anchor: @regatta && dom_id(@regatta))
    end

    def prepare_form
      @organizers = Organizer.all
      @copy_from_regattas = Regatta.order(from_date: :desc)
    end

    def regatta_params
      params.fetch(:regatta, { year: Date.today.year, show_age_categories: :drv,
                               organizer_id: Regatta.last&.organizer_id }).
        permit(:name, :entry_closed, :organizer_id, :year, :from_date, :to_date,
               :currency, :show_age_categories, :show_countries,
               :copy_events_from_regatta_id)
    end

  end
end
