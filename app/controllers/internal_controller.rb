class InternalController < ApplicationController

  is_internal!

  def index
    @current_regatta = Regatta.find_by(id: Parameter.current_regatta_id) || Regatta.last
  end

  def statistics
    @participants_stats = @regatta.participants.left_joins(:event).
      select("COUNT(*) AS total_participants_count, SUM(Abgemeldet) AS withdrawn_participants_count, SUM(Nachgemeldet) AS late_participants_count").
      select("SUM(Meldegeld) AS entry_fee_sum").
      select("SUM((NOT Abgemeldet) * (rennen.RudererAnzahl + IF(rennen.MitSteuermann, 1, 0))) AS starting_rowers_count").
      unscope(:order).first
    @teams_stats = @regatta.teams.where(
      team_id: @regatta.participants.enabled.unscope(:order).select(:team_id)).
      select("COUNT(*) AS total_teams_count").
      unscope(:order).first
    @rower_stats = @regatta.participants.enabled.
      left_joins(Participant::ALL_ROWERS_WITH_CLUBS).
      select('COUNT(DISTINCT ruderer.ID) AS rower_count, COUNT(DISTINCT addressen.ID) AS club_count').
      unscope(:order).first
  end

end