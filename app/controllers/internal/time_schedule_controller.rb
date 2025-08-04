module Internal
  class TimeScheduleController < ApplicationController

    is_internal!

    before_action do
      @time_schedule_service = Services::TimeSchedule.new(@regatta)
    end

    def index
      authorize! :index, Services::TimeSchedule::Block
    end

    def show
      @block = @time_schedule_service.find(params[:id].to_i)
      authorize! :show, @block
    end

    def new
      authorize! :new, Services::TimeSchedule::Block
    end

    def create
      authorize! :create, Services::TimeSchedule::Block

      validate_save_and_render(:new) do
        @time_schedule_service.generate_block(
          params[:event_number_from].to_i, params[:event_number_to].to_i,
          params[:race_type], params[:first_race_letter],
          Time.zone.parse(params[:first_start]), params[:race_interval].to_i.minutes,
          params[:fixed_race_count].presence&.to_i
        )
      end
    end

    def update
      block = @time_schedule_service.find(params[:id].to_i)
      authorize! :update, block

      validate_save_and_render(:show) do
        # Apply data
        case params[:operation].to_s
        when "shift_block"
          block.shift_block(Time.zone.parse(params[:first_start]))
        when "adjust_interval"
          block.adjust_interval(params[:race_interval].to_i.minutes)
        when "insert_break"
          break_start = Time.zone.parse("#{block.first_race_start.to_date} #{break_start}")
          block.insert_break(break_start, params[:break_length].to_i)
        else
          raise "Unknown operation: #{params[:operation]}"
        end

        block
      end
    end

    def destroy
      @block = @time_schedule_service.find(params[:id].to_i)
      authorize! :destroy, @block

      Race.transaction do
        if @block.destroy
          flash[:success] = "Läufe erfolgreich gelöscht"
          redirect_to back_or_default
        else
          flash[:danger] = "Läufe könnten nicht gelöscht werden. Vermutlich existieren bereits Startlisten oder Ergebnisse."
          render :show
        end
      end
    end

    protected

    def validate_save_and_render(on_error_view)
      raise "Block expected" unless block_given?

      block = yield

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
        render on_error_view
      end
    end

    def default_url
      internal_time_schedule_index_url(@regatta)
    end

  end
end