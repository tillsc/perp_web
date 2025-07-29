module Internal
  class ExternalMeasurementsController < InternalController

    is_internal!

    def index
      authorize! :index, ExternalMeasurement

      @measuring_points = @regatta.measuring_points.preload(:regatta)
      @external_measurements = ExternalMeasurement.all.order('time DESC').page(params[:page])
    end


    def new
      @external_measurement = ExternalMeasurement.new(time: DateTime.now)
      authorize! :new, @external_measurement

      prepare_form
    end

    def create
      @external_measurement = ExternalMeasurement.new(measuring_point_params)
      authorize! :create, @external_measurement

      if @external_measurement.save
        flash[:info] = helpers.success_message_for(:create, @external_measurement)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:create, @external_measurement)
        prepare_form
        render :new
      end
    end

    protected

    def default_url
      internal_external_measurements_url(@regatta, anchor: @external_measurement && dom_id(@external_measurement))
    end

    def measuring_point_params
      params[:external_measurement].permit(:time, :measuring_point_number)
    end

    def prepare_form
      @measuring_points = @regatta.measuring_points.preload(:regatta)
    end

  end
end