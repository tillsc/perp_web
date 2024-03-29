module Internal
  class RowersController < ApplicationController

    is_internal!
    respond_to :json, :html

    def index
      @rowers = Rower.all
      @rowers = @rowers.by_filter(params[:query]) if params[:query].present?

      @rowers = @rowers.
        order(year_of_birth: :desc, last_name: :asc, first_name: :asc).
        page(params[:page] || 1)
      respond_with @rowers
    end

    def show
      @rower = Rower.find(params[:id])
      respond_with @rower
    end

    def new
      @rower = Rower.new(rower_params)
      authorize! :new, Rower
      prepare_form
    end

    def create
      @rower = Rower.new(rower_params)
      @rower.set_rower_id
      authorize! :create, Rower

      if @rower.save
        flash[:info] = helpers.success_message_for(:create, @rower)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:create, @rower)
        prepare_form
        render :new
      end
    end

    def edit
      @rower = Rower.find(params[:id])
      authorize! :edit, @rower
      prepare_form
    end

    def update
      @rower = Rower.find(params[:id])
      authorize! :update, @rower

      if @rower.update(rower_params)
        flash[:info] = helpers.success_message_for(:update, @rower)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @rower)
        prepare_form
        render :edit
      end
    end

    def destroy
      rower = Rower.find(params[:id])
      authorize! :destroy, rower

      if rower.destroy
        flash[:info] = helpers.success_message_for(:destroy, rower)
      else
        flash[:danger] = helpers.error_message_for(:destroy, rower)
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      anchor = "rower#{@rower.id}" if @rower
      internal_rowers_url(@regatta, anchor: anchor)
    end

    def prepare_form
      @representatives = Address.representative.order_existing_first(@regatta)
    end

    def rower_params(default = {})
      params.fetch(:rower, default).permit(:first_name, :last_name, :year_of_birth, :external_id, :club_id, :club_name)
    end

  end
end