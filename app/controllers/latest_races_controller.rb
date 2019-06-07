class LatestRacesController < ApplicationController

  def show
    scope = Race.joins(:results).for_regatta(@regatta).now
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.first
    @no_navigation = true
  end

end
