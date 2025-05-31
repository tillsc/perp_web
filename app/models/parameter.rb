class Parameter < ApplicationRecord

  self.table_name = 'parameter'
  self.primary_key = 'Sektion', 'Schluessel'

  alias_attribute :section, 'Sektion'
  alias_attribute :key, 'Schluessel'
  alias_attribute :value, 'Wert'
  alias_attribute :additional, 'Zusatz'

  scope :values_for, -> (section) do
    where('Sektion' => section)
  end

  scope :value_for, -> (section, key) do
    where('Sektion' => section, 'Schluessel' => key)
  end

  def self.get_value_for(section, key)
    self.value_for(section, key).first&.value
  end

  def self.set_value_for!(section, key, value)
    self.value_for(section, key).first_or_create!.
      update!(value: value)
  end

  def self.current_regatta_id
    get_value_for('Global', 'AktRegatta')
  end

  def self.race_type_name(type_short)
    @types_short_to_long ||= {}
    @types_short_to_long[type_short] ||= get_value_for('Uebersetzer_Lauftypen', type_short) || type_short
  end

  def self.all_race_type_names
    @types_short_to_long = values_for('Uebersetzer_Lauftypen').inject({}) do |h, param|
      h.merge(param.key => param.value)
    end

  end

  def self.race_sorter
    race_type_list = get_value_for('Global', 'LauftypSortierung').to_s
    @sorter||= -> (race) {
      race = race.first if race.is_a?(Array) # For Hashes where the race is the key
      [race_type_list.index(race&.type_short || '-').to_s.rjust(2, "0").presence || "Z#{race&.type_short}", race&.number_short]
    }
  end

  def self.race_types_with_implicit_start_list
    @_race_types_with_implicit_start_list||=
      get_value_for('Global', 'LauftypenNachMeldeergebnis').to_s.upcase.split("")
  end

end
