module Internal
  class RegattasController < ApplicationController

    is_internal!

    def index
      @regattas = Regatta.preload(:events).order(from_date: :desc)
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
      end

      Regatta.transaction do
        if @regatta.save
          flash[:info] = 'Regatta angelegt'
          redirect_to back_or_default
        else
          flash[:danger] = "Regatta konnte nicht angelegt werden:\n#{@regatta.errors.full_messages.join(', ')}"
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
        flash[:info] = 'Regatta aktualisiert'
        redirect_to back_or_default
      else
        flash[:danger] = "Regatta konnte nicht gespeichert werden:\n#{@regatta.errors.full_messages.join(', ')}"
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

      if regatta.destroy
        flash[:info] = 'Regatta gelöscht'
      else
        flash[:danger] = "Rennen konnte nicht gelöscht:\n#{regatta.errors.full_messages.join(', ')}"
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      anchor = "regatta_#{@regatta.id}" if @regatta
      internal_regattas_url(anchor: anchor)
    end

    def prepare_form
      @organizers = Organizer.all
    end

    def regatta_params
      params.fetch(:regatta, {year: Date.today.year}).permit(:name, :organizer_id, :year, :from_date, :to_date, :currency)
    end

  end
end