module HasRaceNumber

  extend ActiveSupport::Concern

  included do

    self.class_attribute :race_number_field
    self.race_number_field = :race_number

    scope :by_type_short, -> (type_short) do
      ts = Array(type_short).dup
      scope = arel_table[self.race_number_field].matches("#{ts.pop}%")
      while ts.any?
        scope = scope.or(arel_table[self.race_number_field].matches("#{ts.pop}%"))
      end
      where(scope)
    end

  end

  def race_type_short
    self.race_number.to_s[0]
  end

end