class Event < ApplicationRecord

  self.table_name = 'rennen'
  self.primary_keys = 'Regatta_ID', 'Rennen'

  alias_attribute :number, 'Rennen'
  alias_attribute :name_short, 'NameK'
  alias_attribute :name_de, 'NameD'
  alias_attribute :name_en, 'NameE'
  alias_attribute :start_measuring_point_number, 'StartMesspunktNr'
  alias_attribute :finish_measuring_point_number, 'ZielMesspunktNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :start_measuring_point, class_name: "MeasuringPoint", foreign_key: ['Regatta_ID', 'StartMesspunktNr']
  belongs_to :finish_measuring_point, class_name: "MeasuringPoint", foreign_key: ['Regatta_ID', 'ZielMesspunktNr']

  has_many :participants, foreign_key: ['Regatta_ID', 'Rennen']
  has_many :races, foreign_key: ['Regatta_ID', 'Rennen']
  has_many :starts, foreign_key: ['Regatta_ID', 'Rennen']
  has_many :results, foreign_key: ['Regatta_ID', 'Rennen']

  scope :with_counts, -> {
    select('rennen.*, COUNT(DISTINCT startlisten.tnr, startlisten.lauf) starts_count, COUNT(DISTINCT ergebnisse.tnr, ergebnisse.lauf) results_count').
        left_outer_joins(:starts, :results).
        group('rennen.regatta_id, rennen.rennen')
  }

  default_scope do
    order('Regatta_ID', 'Rennen')
  end

  def name
    self.name_de
  end

  def to_param
    self.number.to_s
  end

  def distance
    finish_measuring_point.position - start_measuring_point.position
  end

end
