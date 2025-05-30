class ExternalMeasurement < ApplicationRecord

  alias_attribute :measuring_point_number, 'MesspunktNr'

  scope :for_measuring_point, -> (measuring_point) {
    number = measuring_point.is_a?(MeasuringPoint) ? measuring_point.number : measuring_point
    where(measuring_point_number: number)
  }

  scope :around, -> (time, delta = 120.seconds) {
    where(arel_table[:time].gteq(time - delta)).
      where(arel_table[:time].lteq(time + delta))
  }

end
