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
      block.set_first_start(params[:first_start])
      if @time_schedule_service.all? { |other_block| other_block == block || !block.intersects?(other_block) }
        save_and_respond!(block)
      else
        render plain: "Es existieren bereits andere Rennen im Zeitraum von #{I18n.l(block.first_race_start)} bis #{I18n.l(block.last_race_end)} Uhr", status: :unprocessable_entity
      end
    rescue RuntimeError => e
      render plain: "Error: #{e}", status: 500
    end

    protected

    def save_and_respond!(block)
      Race.transaction do
        block.save!
        render plain: "Ok"
      rescue ActiveRecord::RecordInvalid => e
        render plain: "Fehler beim Speichern: #{e.record.errors.full_messages.to_sentence}", status: 500
      end
    end
  end

end