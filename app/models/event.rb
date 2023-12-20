class Event < ApplicationRecord

  self.table_name = 'rennen'
  self.primary_key = 'Regatta_ID', 'Rennen'

  alias_attribute :number, 'Rennen'
  alias_attribute :name_short, 'NameK'
  alias_attribute :name_de, 'NameD'
  alias_attribute :name_en, 'NameE'

  alias_attribute :start_measuring_point_number, 'StartMesspunktNr'
  alias_attribute :finish_measuring_point_number, 'ZielMesspunktNr'

  alias_attribute :rower_count, 'RudererAnzahl'
  alias_attribute :is_lightweight, 'Leichtgewicht'
  attribute 'Leichtgewicht', :boolean
  alias_attribute :has_cox, 'MitSteuermann'

  alias_attribute :entry_fee, 'Startgeld'
  alias_attribute :divergent_regatta_name, 'Regattaname'

  alias_attribute :maximum_average_weight, 'MaximalesDurchschnittgewicht'
  alias_attribute :maximum_single_weight, 'MaximalesEinzelgewicht'
  alias_attribute :maximum_cox_weight, 'MinimalesSteuermanngewicht'

  alias_attribute :additional_text, 'Zusatztext1'
  alias_attribute :additional_text_format, 'Zusatztext1Format'

  TEXT_FORMATS = { 0 => 'Keine Formatierung', 1 => 'HTML', 2 => 'RTF' }

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :start_measuring_point, class_name: "MeasuringPoint", query_constraints: ['Regatta_ID', 'StartMesspunktNr']
  belongs_to :finish_measuring_point, class_name: "MeasuringPoint", query_constraints: ['Regatta_ID', 'ZielMesspunktNr']

  has_many :participants, query_constraints: ['Regatta_ID', 'Rennen']
  has_many :races, query_constraints: ['Regatta_ID', 'Rennen']
  has_many :starts, query_constraints: ['Regatta_ID', 'Rennen']
  has_many :results, query_constraints: ['Regatta_ID', 'Rennen']

  scope :with_counts, -> {
    select('rennen.*, COUNT(DISTINCT startlisten.tnr, startlisten.lauf) starts_count, COUNT(DISTINCT ergebnisse.tnr, ergebnisse.lauf) results_count').
        left_outer_joins(:starts, :results).
        group('rennen.regatta_id, rennen.rennen')
  }

  default_scope do
    order('Regatta_ID', 'Rennen')
  end

  scope :to_be_weighed, -> {
    where(is_lightweight: true).or(where(has_cox: true)).
      joins(:participants, races: :starts).
      #  merge(Participant.enabled).
      joins("LEFT JOIN gewichte g ON TO_DAYS(g.Datum) = TO_DAYS(#{Race.table_name}.Sollstartzeit) AND (#{Participant.table_name}.Ruderer1_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer2_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer3_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer4_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer5_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer6_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer7_ID = g.Ruderer_ID OR #{Participant.table_name}.Ruderer8_ID = g.Ruderer_ID)").
      joins("LEFT JOIN gewichte gSt ON TO_DAYS(gSt.Datum) = TO_DAYS(#{Race.table_name}.Sollstartzeit) AND (#{Participant.table_name}.RudererS_ID = gSt.Ruderer_ID)").
      select("#{self.table_name}.*").
      select("COUNT(DISTINCT #{Participant.table_name}.TNr) AS participants_count").
      select("COUNT(DISTINCT g.Ruderer_ID) AS rower_weights_count").
      select("COUNT(DISTINCT #{Participant.table_name}.TNr) * #{Event.table_name}.RudererAnzahl AS rower_count").
      select("COUNT(DISTINCT gSt.Ruderer_ID) AS cox_weights_count").
      select("COUNT(DISTINCT #{Participant.table_name}.TNr) * #{Event.table_name}.MitSteuermann AS cox_count").
      select("MIN(#{Race.table_name}.Sollstartzeit) AS min_started_at").
      select("MAX(#{Race.table_name}.WiegelisteFreigegeben) AS approved").
      group("#{Race.table_name}.Rennen")
  }

  def label
    "#{self.number} - #{self.name_short}"
  end

  def name
    self.name_de
  end

  def distance
    finish_measuring_point.position - start_measuring_point.position
  end

  def distance_for(measuring_point)
    measuring_point.position - start_measuring_point.position
  end

  def measuring_point_type(measuring_point_or_measuring_point_number)
    mp_number = MeasuringPoint.number(measuring_point_or_measuring_point_number)
    if start_measuring_point_number == mp_number
      :start
    elsif finish_measuring_point_number == mp_number
      :finish
    elsif mp_number.between?(start_measuring_point_number, finish_measuring_point_number)
      :split_time
    else
      nil
    end
  end

end
