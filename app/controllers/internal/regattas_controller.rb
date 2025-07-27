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

      if last_regatta = Regatta.last
        @regatta.measuring_points = last_regatta.measuring_points.map do |mp|
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
          flash[:info] = helpers.success_message_for(:create, @regatta)
          redirect_to back_or_default
        else
          flash[:danger] = helpers.error_message_for(:create, @regatta)
          prepare_form
          render :new
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
        render :edit
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
      internal_regattas_url(anchor: @regatta&.to_anchor)
    end

    def prepare_form
      @organizers = Organizer.all
    end

    def regatta_params
      params.fetch(:regatta, {year: Date.today.year}).
        permit(:name, :entry_closed, :organizer_id, :year, :from_date, :to_date,
               :currency, :show_age_categories, :show_countries)
    end

  end
end