class ResultTime < ApplicationRecord

  self.table_name = 'zeiten'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr', 'MesspunktNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, query_constraints: ['Regatta_ID', 'Rennen']
  belongs_to :race, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf']
  belongs_to :result, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf', 'TNr']

  belongs_to :measuring_point, query_constraints: ['Regatta_ID', 'MesspunktNr']

  belongs_to :participant, query_constraints: ['Regatta_ID', 'Rennen', 'TNr']

  alias_attribute :race_number, 'Lauf'
  alias_attribute :measuring_point_number, 'MesspunktNr'
  alias_attribute :time, 'Zeit'

  default_scope do
    order('Regatta_ID', 'Rennen', 'Lauf', 'MesspunktNr', 'Zeit')
  end

  def self.sanitize_time(t)
    t.to_s.gsub(/^00:/, "").gsub(".", ",").presence
  end

  def to_time
    time && "00:#{time.gsub(',', '.')}".to_time
  end

  def sort_time_str
    to_time&.strftime("%2H:%2M:%2S.%2N")
  end

end
