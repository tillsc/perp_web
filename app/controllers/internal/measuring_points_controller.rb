module Internal
  class MeasuringPointsController < ApplicationController

    is_internal!

    def index
      @measuring_points = MeasuringPoint.for_regatta(@regatta).preload(:measuring_session)
    end

    def new
      @measuring_point = @regatta.measuring_points.new

      authorize! :new, @measuring_point
      prepare_form
    end

    def create
      @measuring_point = @regatta.measuring_points.new(measuring_point_params)
      authorize! :create, @measuring_point

      if @measuring_point.save
        flash[:info] = helpers.success_message_for(:create, @measuring_point)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:create, @measuring_point)
        prepare_form
        render :new
      end
    end

    def edit
      @measuring_point = @regatta.measuring_points.find(params.extract_value(:id))
      authorize! :edit, @measuring_point
      prepare_form
    end

    def update
      @measuring_point = @regatta.measuring_points.find(params.extract_value(:id))
      authorize! :update, @measuring_point

      if @measuring_point.update(measuring_point_params)
        flash[:info] = helpers.success_message_for(:update, @measuring_point)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @measuring_point)
        prepare_form
        render :edit
      end
    end

    def destroy
      measuring_point = @regatta.measuring_points.find(params.extract_value(:id))
      authorize! :destroy, measuring_point

      if measuring_point.destroy
        flash[:info] = helpers.success_message_for(:destroy, measuring_point)
      else
        flash[:danger] = helpers.error_message_for(:destroy, measuring_point)
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      internal_measuring_points_url(@regatta, anchor: @measuring_point&.to_anchor)
    end

    def prepare_form
    end

    def measuring_point_params(default = {})
      params.fetch(:measuring_point, default).
        permit(:number, :position, :measuring_session_id,
               :finish_cam_base_url, :backup_finish_cam_base_url)
    end

  end
end