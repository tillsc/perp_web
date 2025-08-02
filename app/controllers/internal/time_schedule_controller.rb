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

    def new

    end

    def create

    end

    def update
      block = @time_schedule_service.find(params[:id].to_i)
      authorize! :update, block

      # Apply data
      case params[:operation].to_s
      when "shift_block"
        block.shift_block(Time.parse(params[:first_start]))
      when "adjust_interval"
        block.adjust_interval(params[:race_interval].to_i.minutes)
      when "insert_break"
        break_start = Time.zone.parse("#{block.first_race_start.to_date} #{break_start}")
        block.insert_break(break_start, params[:break_length].to_i)
      else
        raise "Unknown operation: #{params[:operation]}"
      end

      success = false
      # Validate and save
      if @time_schedule_service.none? { |other_block| other_block != block && block.intersects?(other_block) }
        Race.transaction do
          success = block.save!
        end
      else
        flash.now[:danger] = "Es existieren bereits andere Rennen im Zeitraum von #{I18n.l(block.first_race_start)} bis #{I18n.l(block.last_race_start)} Uhr"
      end
      if success
        flash.now[:success] = I18n.t("helpers.success.update", model: Services::TimeSchedule::Block.model_name.human)
      end

    rescue ActiveRecord::RecordInvalid => e
      flash.now[:danger] = "Fehler beim Speichern: #{e.record.errors.full_messages.to_sentence}"
    rescue RuntimeError => e
      flash.now[:danger] = "Allgemeiner Fehler: #{e}"

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

    protected

    def default_url
      internal_time_schedule_index_url(@regatta)
    end

  end
end