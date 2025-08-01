module Internal
  class TimeScheduleController < ApplicationController

    is_internal!

    before_action do
      @time_schedule_service = Services::TimeSchedule.new(@regatta.races.preload(:event, :starts, :results))
    end

    def index
      authorize! :index, Services::TimeSchedule::Block
    end

    def show
      @block = @time_schedule_service.find(params[:id].to_i)
      authorize! :show, @block
    end

    def set_first_start
      block = @time_schedule_service.find(params[:id].to_i)
      authorize! :update, block

      validate_save_and_respond!(block) do
        block.set_first_start(params[:first_start])
      end
    end

    def insert_break
      block = @time_schedule_service.find(params[:id].to_i)
      authorize! :update, block

      validate_save_and_respond!(block) do
        block.insert_break(params[:break_start], params[:break_length].to_i)
      end
    end

    protected

    def validate_save_and_respond!(block, &operation_block)
      success = false

      operation_block.call

      if @time_schedule_service.none? { |other_block| other_block != block && block.intersects?(other_block) }
        Race.transaction do
          success = block.save!
        end
      else
        flash.now[:danger] = "Es existieren bereits andere Rennen im Zeitraum von #{I18n.l(block.first_race_start)} bis #{I18n.l(block.last_race_start)} Uhr"
      end
      if success
        flash.now[:success] = I18n.t("helpers.success.update", model: "Block")
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:danger] = "Fehler beim Speichern: #{e.record.errors.full_messages.to_sentence}"
    rescue RuntimeError => e
      flash.now[:danger] = "Error: #{e}"
    ensure
      # Render
      if request.format.json? || request.xhr?
        if success
          render json: {info: flash.to_hash.values.compact.join(", ")}
        else
          render json: {error: flash.to_hash.values.compact.join(", ")}, status: :unprocessable_entity
        end
        flash.discard
      elsif success
        redirect_to back_or_default
      else
        @block = block
        render :show
      end
    end

    def default_url
      internal_time_schedule_url(@regatta)
    end

  end
end