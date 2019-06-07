class LatestRacesController < ApplicationController

  def show
    scope = Race.joins(:results).for_regatta(@regatta).latest
    scope = scope.by_type_short(params[:type_short]) if params[:type_short].present?
    @race = scope.first
    @no_navigation = true
  end

end
