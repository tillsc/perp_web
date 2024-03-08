module Internal
  class WeighingsController < ApplicationController

    is_internal!

    before_action :init_filters

    def index
      @events = @regatta.events.to_be_weighed.with_weight_info(@date)
      @events = @events.where(Event.arel_table[:number].gteq(@filters[:event_number_from])) if @filters[:event_number_from]
      @events = @events.where(Event.arel_table[:number].lteq(@filters[:event_number_to])) if @filters[:event_number_to]

      if @filters[:only_not_weighed]
        @events = @events.select do |event|
          (event.is_lightweight? && event.expected_rower_weights_count != event.rower_weights_count) ||
            (event.has_cox? && event.expected_cox_weights_count != event.cox_weights_count)
        end
      end
    end

    def event
      @event = @regatta.events.to_be_weighed.find(params.extract_value(:id))
      @participants = @event.participants.
        with_weight_info(@date).
        preload(:team, Participant::ALL_ROWERS_WITH_WEIGHTS)
    end

    def rowers
      participants = @regatta.participants.
        merge(Event.to_be_weighed). # :event is joined by .with_weight_info
        with_weight_info(@date).
        preload(:event, :team, Participant::ALL_ROWERS_WITH_WEIGHTS)
      participants = participants.where(Participant.arel_table[:event_number].gteq(@filters[:event_number_from])) if @filters[:event_number_from]
      participants = participants.where(Participant.arel_table[:event_number].lteq(@filters[:event_number_to])) if @filters[:event_number_to]

      @rowers = participants.
        inject({}) { |hash, p|
          fields = []
          if (p.event.is_lightweight?)
            fields+= (Participant::ALL_ROWERS - [:rowers])
          end
          if (p.event.has_cox?)
            fields<< :rowers
          end
          fields.each do |fn|
            next unless r = p.send(fn)
            hash[r]||= []
            hash[r] << p
          end
          hash
        }.sort_by { |r, _p| [r.last_name, r.first_name] }.to_h
      @rowers = @rowers.reject { |r, _p| r.weight_for(@date).present? } if @filters[:only_not_weighed]
    end

    def rower
      @rower = Rower.find(params[:id])
      @participants = @regatta.participants.
        merge(Event.to_be_weighed). # :event is joined by .with_weight_info
        with_weight_info(@date).
        for_rower(@rower).
        preload(:event, :team, Participant::ALL_ROWERS_WITH_WEIGHTS)
    end

    def save_weight
      rower = Rower.find(params[:id])
      weight = rower.weight_for(@date) || rower.weights.build(date: @date)
      if params[:weight].present?
        time = DateTime.parse(params[:time])
        weight.date = weight.date.change(hour: time.hour, min: time.minute, sec: time.second)
        weight.weight = params[:weight]
        weight.save!
        flash[:info] = "Gewicht gespeichert"
      elsif weight.persisted?
        weight.destroy!
        flash[:info] = "Gewicht gelöscht"
      end
      if params[:back_to_referrer] && params[:referrer]
        redirect_to params[:referrer]
      else
        redirect_to internal_rower_weighings_url(@regatta, rower, @filters.merge(referrer: params[:referrer]))
      end
    end

    protected

    def init_filters
      @date = params[:date].to_date

      @filters = { date: @date }
      if params[:event_number_from].present?
        @filters[:event_number_from] = params[:event_number_from].presence&.to_i
      end
      if params[:event_number_to].present?
        @filters[:event_number_to] = [params[:event_number_to].to_i, @filters[:event_number_from]].compact.max
      end
      @filters[:only_not_weighed] = true if ['1', 'true'].include?(params[:only_not_weighed])
    end

  end
end