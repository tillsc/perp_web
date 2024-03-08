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
  attribute 'MitSteuermann', :boolean

  alias_attribute :entry_fee, 'Startgeld'
  alias_attribute :divergent_regatta_name, 'Regattaname'

  alias_attribute :maximum_average_rower_weight, 'MaximalesDurchschnittgewicht'
  alias_attribute :maximum_rower_weight, 'MaximalesEinzelgewicht'
  alias_attribute :minimum_cox_weight, 'MinimalesSteuermanngewicht'

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
    where(is_lightweight: true).or(where(has_cox: true))
  }

  scope :with_weight_info, -> (date) {
    scope = joins(races: {starts: :participant})
      .merge(Race.planned_for(date))
    Weight.apply_info_scope(scope, date).
      select("#{self.table_name}.*").
      group("#{Race.table_name}.Rennen")
  }

  def label
    "#{self.number} - #{self.name_short}"
  end

  def name
    self.name_de
  end

  def distance
    if finish_measuring_point && start_measuring_point
      finish_measuring_point.position - start_measuring_point.position
    else
      0
    end
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
