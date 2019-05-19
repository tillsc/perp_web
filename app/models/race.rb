class Race < ApplicationRecord

  self.table_name = 'laeufe'
  self.primary_keys = 'Regatta_ID', 'Rennen', 'Lauf'

  alias_attribute :number, 'Lauf'
  alias_attribute :started_at_time, 'IstStartZeit'
  alias_attribute :planned_for, 'SollStartZeit'

  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']

  has_many :starts, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  scope :latest, -> do
    where.not('IstStartZeit' => nil).order('DATE(SollStartZeit) DESC, IstStartZeit DESC')
  end

  scope :for_regatta, -> (regatta) do
    includes(:event).where(Event.table_name => { regatta_id: regatta.id })
  end

  scope :by_type_short, -> (type_short) do
    where(arel_table['Lauf'].matches("#{type_short}%"))
  end

  def name
    "#{Parameter.race_type_name(self.type_short)} #{self.number_short}"
  end

  def type_short
    self.number.to_s[0]
  end

  def number_short
    self.number.to_s[1]
  end

  def started_at
    return unless started_at_time && planned_for

    DateTime.new(planned_for.year, planned_for.month, planned_for.day, started_at_time.hour, started_at_time.min, started_at_time.sec)
  end

end
