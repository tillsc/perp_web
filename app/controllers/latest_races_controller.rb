class LatestRacesController < ApplicationController

  TV_PARAMETER_KEYS = {
    header_space_left: 'HeaderSpaceLeft',
    footer_space_left: 'FooterSpaceLeft',
    background_color: 'BackgroundColor',
    font_size: 'FontSize'
  }

  before_action :load_settings

  def index
    @measuring_points = MeasuringPoint.for_regatta(@regatta)
  end

  def show
    scope = Race.joins(:results).for_regatta(@regatta).now
    scope = Race.with_finish_times if params[:testmode] == "1"
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    scope = scope.with_times_at(params[:measuring_point_number]) if params[:measuring_point_number].present?
    @race = scope.preload(event: [:start_measuring_point, :finish_measuring_point], results: [:times, participant: :team]).first
    @measuring_point = if params[:measuring_point_number].present?
                         MeasuringPoint.find([@regatta.ID, params[:measuring_point_number]])
                       else
                         max_measuring_point_number = @race && @race.results.map { |r| r.times.map(&:measuring_point_number).max }.compact.max
                         max_measuring_point_number && MeasuringPoint.find([@regatta.ID, max_measuring_point_number])
                       end
    @results = @race && @race.results.sort_by { |r| r.time_for(@measuring_point)&.sort_time_str || 'ZZZZZZZZZ' }
    render :layout => 'minimal'
  end

  def latest_winner
    scope = Race.for_regatta(@regatta).with_finish_times.stated_minutes_ago(30)
    scope = Race.with_finish_times if params[:testmode] == "1"
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.preload(event: [:start_measuring_point, :finish_measuring_point], results: [:times, participant: [:team, *Participant::ALL_ROWERS]]).first
    @event = @race && @race.event
    @result = @race && @event && @race.results.
        select { |r| r.time_for(@event.finish_measuring_point)&.time }.
        sort_by { |r| r.time_for(@event.finish_measuring_point)&.sort_time_str }.
        first
    render :layout => 'minimal'
  end

  def current_start
    scope = Race.with_starts.for_regatta(@regatta).current_start
    scope = Race.with_starts if params[:testmode] == "1"
    scope = scope.by_type_short(params[:type_short].to_s.split(',')) if params[:type_short].present?
    @race = scope.preload(:event, starts: { participant: :team }).first
    @event = @race && @race.event

    render :layout => 'minimal'
  end

  def update
    authorize! :update, :tv_settings

    TV_PARAMETER_KEYS.each do |param_name, key|
    Parameter.set_value_for!("Tv", key, params[param_name].presence)
    end

    redirect_to tv_path(@regatta)
  end

  protected

  def load_settings
    parameters = Parameter.values_for('Tv').to_a
    TV_PARAMETER_KEYS.each do |param_name, key|
      instance_variable_set("@#{param_name}", parameters.find { |p| p.key == key }&.value.presence)
    end
  end

end
