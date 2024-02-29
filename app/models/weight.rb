class Weight < ApplicationRecord

  self.table_name = 'gewichte'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :rower, foreign_key: 'Ruderer_ID'

  alias_attribute :weight, 'Gewicht'
  alias_attribute :date, 'Datum'

  default_scope do
    order('Datum', 'Ruderer_ID')
  end

  # Adds info columns for weighting.
  #
  # Assumes tables/relationships :event, :race and :participant to be present/joined correctly before
  def self.apply_info_scope(outer_scope, date)
    outer_scope.
      joins("LEFT JOIN gewichte g ON TO_DAYS(g.Datum) = TO_DAYS('#{date.to_date}') AND (#{Participant.table_name}.Ruderer1_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer2_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer3_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer4_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer5_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer6_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer7_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer8_ID = g.Ruderer_ID)").
      joins("LEFT JOIN gewichte gSt ON TO_DAYS(gSt.Datum) = TO_DAYS('#{date.to_date}') AND (#{Participant.table_name}.RudererS_ID = gSt.Ruderer_ID)").
      select("AVG(g.Gewicht) AS average_rower_weight").
      select("MAX(g.Gewicht) AS maximum_rower_weight").
      select("MAX(gSt.Gewicht) AS maximum_cox_weight").
      select("COUNT(DISTINCT #{Participant.table_name}.TNr) AS participants_count").
      select("COUNT(DISTINCT g.Ruderer_ID) AS rower_weights_count").
      select("COUNT(DISTINCT #{Participant.table_name}.TNr) * #{Event.table_name}.RudererAnzahl AS expected_rower_weights_count").
      select("COUNT(DISTINCT gSt.Ruderer_ID) AS cox_weights_count").
      select("COUNT(DISTINCT #{Participant.table_name}.TNr) * #{Event.table_name}.MitSteuermann AS expected_cox_weights_count").
      select("MIN(#{Race.table_name}.Sollstartzeit) AS min_started_at").
      select("MAX(#{Race.table_name}.WiegelisteFreigegeben) AS approved")
  end

end
