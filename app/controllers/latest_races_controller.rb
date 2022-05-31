class LatestRacesController < ApplicationController

  def index

  end

  def show
    scope = Race.joins(:results).for_regatta(@regatta).now
    scope = Race.with_finish_times if params[:testmode] == "1"
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.first
    max_measuring_point_number = @race && @race.results.map { |r| r.times.map(&:measuring_point_number).max }.compact.max
    @measuring_point = max_measuring_point_number && MeasuringPoint.find([@regatta.ID, max_measuring_point_number])
    @results = @race && @race.results.sort_by { |r| r.time_for(@measuring_point).try(:time) || 'ZZZZZZZZZ' }
    render :layout => 'minimal'
  end

  def latest_winner
    scope = Race.for_regatta(@regatta).with_finish_times.stated_minutes_ago(30)
    scope = Race.with_finish_times if params[:testmode] == "1"
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.first
    @event = @race && @race.event
    @result = @race && @event && @race.results.
        select { |r| r.time_for(@event.finish_measuring_point).try(:time) }.
        sort_by { |r| r.time_for(@event.finish_measuring_point).try(:time) }.
        first
    render :layout => 'minimal'
  end

  def current_start
    scope = Race.with_starts.for_regatta(@regatta).current_start
    scope = Race.with_starts if params[:testmode] == "1"
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.first
    @event = @race && @race.event

    render :layout => 'minimal'
  end

end
