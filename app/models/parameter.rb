class Parameter < ApplicationRecord

  self.table_name = 'parameter'
  self.primary_keys = 'Sektion', 'Schluessel'

  alias_attribute :section, 'Sektion'
  alias_attribute :key, 'Schluessel'
  alias_attribute :value, 'Wert'

  scope :value_for, -> (section, key) do
    where('Sektion' => section, 'Schluessel' => key)
  end

  def self.current_regatta_id
    value_for('Global', 'AktRegatta').first.try(:value)
  end

  def self.race_type_name(type_short)
    @types_short_to_long ||= {}
    @types_short_to_long[type_short] ||= value_for('Uebersetzer_Lauftypen', type_short).first.try(:value)
  end

  def self.race_sorter
    race_type_list = value_for('Global', 'LauftypSortierung')
    @sorter||= -> (race) {
      race = race.first if race.is_a?(Array) # For Hashes where the race is the key
        [race_type_list.index(race.type_short).to_s.presence || "Z#{race.type_short}", race.number_short]
    }
  end

  def self.race_types_with_implicit_start_list
    @_race_types_with_implicit_start_list||=
      value_for('Global', 'LauftypenNachMeldeergebnis').first&.value.to_s.upcase.split("")
  end

end
