class MeasuringPoint < ApplicationRecord

  self.table_name = 'messpunkte'
  self.primary_keys = 'Regatta_ID', 'MesspunktNr'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :measuring_session, optional: true

  alias_attribute :number, 'MesspunktNr'
  alias_attribute :position, 'Position'

  default_scope do
    order('Regatta_ID', 'MesspunktNr')
  end

  scope :for_regatta, -> (regatta) {
    where(regatta_id: regatta.id)
  }

  scope :for_event, -> (event) {
      where(arel_table[:MesspunktNr].gt(event.start_measuring_point_number)).
          where(arel_table[:MesspunktNr].lteq(event.finish_measuring_point_number))
  }

  def name
    self.position.to_s + 'm'
  end

  def to_param
    self.number.to_s
  end

  def self.number(measuring_point_or_measuring_point_number)
    if measuring_point_or_measuring_point_number.is_a?(MeasuringPoint)
      measuring_point_or_measuring_point_number.number
    else
      measuring_point_or_measuring_point_number
    end
  end

end
