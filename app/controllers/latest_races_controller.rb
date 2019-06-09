class LatestRacesController < ApplicationController

  def show
    scope = Race.joins(:results).for_regatta(@regatta).now
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.first
    @no_navigation = true
    max_measuring_point_number = @race.results.map { |r| r.times.map(&:measuring_point_number).max }.compact.max
    @measuring_point = MeasuringPoint.find([@regatta.ID, max_measuring_point_number])
    render :layout => 'minimal'
  end

end
