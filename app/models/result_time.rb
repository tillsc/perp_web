class ResultTime < ApplicationRecord

  self.table_name = 'zeiten'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf', 'TNr', 'MesspunktNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']
  belongs_to :race, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']
  belongs_to :result, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf', 'TNr']

  belongs_to :measuring_point, foreign_key: ['Regatta_ID', 'MesspunktNr']

  belongs_to :participant, foreign_key: ['Regatta_ID', 'Rennen', 'TNr']

  alias_attribute :regatta_id, 'Regatta_ID'
  alias_attribute :event_number, 'Rennen'
  alias_attribute :race_number, 'Lauf'
  alias_attribute :measuring_point_number, 'MesspunktNr'
  alias_attribute :time, 'Zeit'

  default_scope do
    order(arel_table[:regatta_id].asc, arel_table[:event_number].asc,
          arel_table[:race_number].asc, arel_table[:measuring_point_number].asc,
          arel_table[:time].asc)

  end

  def subtract_time(t)
    if t.is_a? ResultTime
      t = t.to_time
    end
    if t.is_a?(Time) && self.time.present?
      "+#{ResultTime.sanitize_time(Time.zone.at(self.to_time - t).utc, remove_empty_minutes_too: true)}"
    else
      nil
    end
  end

  def self.sanitize_time(t, remove_empty_minutes_too: false)
    if t.is_a?(Time)
      t = Services::Measuring.ftime(t)
    end
    reg = remove_empty_minutes_too ? /^00:00:/ : /^00:/
    t.to_s.gsub(reg, "").gsub(".", ",").presence
  end

  def to_time
    time && "00:#{time.gsub(',', '.')}".to_time
  end

  def sort_time_str
    to_time&.strftime("%2H:%2M:%2S.%2N")
  end

end
