class InternalController < ApplicationController

  is_internal!

  def index
    @current_regatta = Regatta.find_by(id: Parameter.current_regatta_id) || Regatta.last
  end

  def statistics
    authorize! :show, :statistics

    starting_rowers =
      Arel::Nodes::Multiplication.new(
        Arel.sql("(#{Arel::Nodes::Subtraction.new(1, Event.bool_to_int_sql(Participant.arel_table[:withdrawn])).to_sql})"),
        Arel::Nodes::Addition.new(Event.arel_table[:rower_count], Event.bool_to_int_sql(Event.arel_table[:has_cox]))
      ).sum.as("starting_rowers_count")

    @participants_stats = @regatta.participants.
      left_joins(:event).
      select(
        Arel.star.count.as("total_participants_count"),
        Participant.bool_to_int_sql(Participant.arel_table[:withdrawn]).sum.as("withdrawn_participants_count"),
        Participant.bool_to_int_sql(Participant.arel_table[:late_entry]).sum.as("late_participants_count"),
        Participant.arel_table[:entry_fee].sum.as("entry_fee_sum"),
        starting_rowers
      ).
      unscope(:order).to_a.first

    @nations = @regatta.teams.
      where(team_id: @regatta.participants.enabled.unscope(:order).select(:team_id)).
      distinct.pluck(:country).map(&:presence).compact.sort
    @teams_stats = @regatta.teams.where(
      team_id: @regatta.participants.enabled.unscope(:order).select(:team_id)).
      select("COUNT(*) AS total_teams_count").
      unscope(:order).to_a.first
    @rower_stats = Rower.for_regatta(@regatta, join_clubs: true).
      select(
        Rower.arel_table[:id].count(true).as("rower_count"),
        Address.arel_table[:id].count(true).as("club_count")
      ).
      unscope(:order).to_a.first
  end

end