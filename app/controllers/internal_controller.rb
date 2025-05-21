class InternalController < ApplicationController

  is_internal!

  def index
    @current_regatta = Regatta.find_by(id: Parameter.current_regatta_id) || Regatta.last
  end

  def statistics
    @stats = @regatta.participants.
      select("COUNT(*) as total_participants_count, SUM(Abgemeldet) as withdrawn_participants_count, SUM(Nachgemeldet) as late_participants_count").
      select("SUM(Meldegeld) AS entry_fee_sum").
      select("SUM((NOT Abgemeldet) * (rennen.RudererAnzahl + IF(rennen.MitSteuermann, 1, 0))) AS starting_rowers_count").
      left_joins(:event).unscope(:order).first
  end

end