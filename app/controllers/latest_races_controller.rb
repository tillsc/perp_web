class LatestRacesController < ApplicationController

  def index
    @races = Race.joins(:results).for_regatta(@regatta).latest.limit(100)
  end

  def show
    scope = Race.for_regatta(@regatta).latest
    scope = scope.by_type_short(params[:type_short]) if params[:type_short].present?
    @race = scope.first
  end

end
