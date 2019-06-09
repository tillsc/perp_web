class LatestRacesController < ApplicationController

  def show
    scope = Race.joins(:results).for_regatta(@regatta).now
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.first
    max_measuring_point_number = @race && @race.results.map { |r| r.times.map(&:measuring_point_number).max }.compact.max
    @measuring_point = max_measuring_point_number && MeasuringPoint.find([@regatta.ID, max_measuring_point_number])
    @results = @race.results.sort_by { |r| r.time_for(@measuring_point).try(:time) || 'ZZZZZZZZZ' }
    render :layout => 'minimal'
  end

  def latest_winner
    @measuring_point = @regatta.measuring_points.last
    scope = Race.joins(results: :times).where('zeiten.MesspunktNr', @measuring_point.number).for_regatta(@regatta).stated_minutes_ago(30)
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.first
    @result = @race && @race.results && @race.results.sort_by { |r| r.time_for(@measuring_point).try(:time) || 'ZZZZZZZZZ' }.first
    render :layout => 'minimal'
  end

end
