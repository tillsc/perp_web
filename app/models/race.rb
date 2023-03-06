class Race < ApplicationRecord

  self.table_name = 'laeufe'
  self.primary_keys = 'Regatta_ID', 'Rennen', 'Lauf'

  alias_attribute :number, 'Lauf'
  alias_attribute :event_number, 'Rennen'
  alias_attribute :started_at_time, 'IstStartZeit'
  alias_attribute :planned_for, 'SollStartZeit'
  alias_attribute :official_since, 'ErgebnisEndgueltig'
  alias_attribute :result_corrected, 'ErgebnisKorrigiert'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']

  has_many :starts, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']
  has_many :results, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  has_many :measurement_sets, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf']

  scope :latest, -> do
    where.not('IstStartZeit' => nil).order('DATE(SollStartZeit) DESC, IstStartZeit DESC')
  end

  scope :upcoming, -> do
    where(arel_table['SollStartZeit'].gteq(1.hour.ago)).where('IstStartZeit' => nil).
      where("(SELECT COUNT(*) FROM #{Participant.table_name} m WHERE m.Regatta_ID = #{Event.table_name}.Regatta_ID AND m.Rennen = #{Event.table_name}.Rennen) > 1 OR (SELECT COUNT(*) FROM #{Start.table_name} s WHERE s.Regatta_ID = #{Event.table_name}.Regatta_ID AND s.Rennen = #{Event.table_name}.Rennen) > 0").
      order('SollStartZeit')
  end

  scope :for_regatta, -> (regatta) do
    includes(:event).where(Event.table_name => { regatta_id: regatta.id })
  end

  scope :with_results, -> do
    joins(:results).group('laeufe.Rennen, laeufe.Lauf')
  end

  scope :with_finish_times, -> do
    joins(:event, results: :times).
      where('zeiten.MesspunktNr = rennen.ZielMesspunktNr AND zeiten.Zeit IS NOT NULL')
  end

  scope :with_starts, -> do
    joins(:starts).group('laeufe.Rennen, laeufe.Lauf')
  end

  scope :by_type_short, -> (type_short) do
    ts = Array(type_short).dup
    scope = arel_table['Lauf'].matches("#{ts.pop}%")
    while ts.any?
      scope = scope.or(arel_table['Lauf'].matches("#{ts.pop}%"))
    end
    where(scope)
  end

  scope :now, -> do
    where(arel_table['IstStartZeit'].between((12.minutes.ago)..(Time.current.getlocal))).
        where('DATE(SollStartZeit) = ?', Date.today).
        order('DATE(SollStartZeit) DESC, IstStartZeit DESC')
  end

  scope :nearby, -> do
    where(arel_table['SollStartZeit'].between((20.minutes.ago)..(20.minutes.since)))
  end

  scope :stated_minutes_ago, -> (minutes) do
    where(arel_table['IstStartZeit'].between((minutes.minutes.ago)..(Time.current.getlocal))).
        where('DATE(SollStartZeit) = ?', Date.today).
        order('DATE(SollStartZeit) DESC, IstStartZeit DESC')
  end

  #
  scope :current_start, -> do
    where(arel_table['IstStartZeit'].eq(nil).or(
      arel_table['IstStartZeit'].gt(2.minutes.ago)
    )).
      where('DATE(SollStartZeit) = ?', Date.today).
      order('DATE(SollStartZeit) DESC, IstStartZeit DESC')
  end

  def name
    "#{Parameter.race_type_name(self.type_short)} #{self.number_short}"
  end

  def full_name
    "Rennen #{event.number} - #{self.name}"
  end

  def type_name
    Parameter.race_type_name(self.type_short)
  end

  def is_official?
    self.official_since.present?
  end

  def type_short
    self.number.to_s[0]
  end

  def number_short
    self.number.to_s[1]
  end

  def numeric_number
    n = self.number.to_s[1]
    if (n.to_i > 0)
      n.to_i
    else
      n.upcase.ord - 'A'.ord + 1
    end
  end

  def started_at
    return unless started_at_time && planned_for

    DateTime.new(planned_for.year, planned_for.month, planned_for.day, started_at_time.hour, started_at_time.min, started_at_time.sec, planned_for.to_datetime.offset, 24)
  end

  def to_param
    self.number
  end

  def measurement_set_for(measuring_point_or_measuring_point_number)
    mp_number = MeasuringPoint.number(measuring_point_or_measuring_point_number)
    measurement_sets.find { |ms| ms.measuring_point_number == mp_number }
  end

  SLOWEST_M_PER_SECOND = 200/60.0
  def upcoming_measurement_for(measuring_point)
    return false if measurement_set_for(measuring_point).present?

    distance = event.distance_for(measuring_point)
    if distance == 0
      started_at.blank? && planned_for &&
        planned_for > 30.minutes.ago && planned_for < 5.minutes.since
    else
      started_at &&
        (started_at >= (distance / SLOWEST_M_PER_SECOND).seconds.ago)
    end
  end

end
