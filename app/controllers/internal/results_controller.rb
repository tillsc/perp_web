module Internal
  class ResultsController < ApplicationController

    def edit
      @race = @regatta.races.find(params.extract_value(:race_id))
      @result = @race.results.find(params.extract_value(:id))
      authorize! :edit, @result
    end

    def update
      @race = @regatta.races.find(params.extract_value(:race_id))
      @result = @race.results.find(params.extract_value(:id))
      authorize! :update, @result

      Result.transaction do
        if @result.update(result_params)
          flash[:info] = helpers.success_message_for(:update, @result)
          redirect_to back_or_default
        else
          flash[:danger] = helpers.error_message_for(:update, @result)
          render :edit
        end
      end
    end

    def destroy
      race = @regatta.races.find(params.extract_value(:race_id))
      result = race.results.find(params.extract_value(:id))
      authorize! :destroy, result

      if result.destroy
        flash[:info] = helpers.success_message_for(:destroy, result)
      else
        flash[:danger] = helpers.error_message_for(:destroy, result)
      end
      redirect_to back_or_default
    end

    protected

    def result_params(default = {})
      params.fetch(:result, default).permit(:lane_number, :disqualified, :comment,
                                            times_hash: {})
    end

  end
end