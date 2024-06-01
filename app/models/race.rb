class Race < ApplicationRecord

  self.table_name = 'laeufe'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf'

  alias_attribute :number, 'Lauf'
  alias_attribute :event_number, 'Rennen'
  alias_attribute :started_at_time, 'IstStartZeit'
  alias_attribute :planned_for, 'SollStartZeit'

  alias_attribute :result_official_since, 'ErgebnisEndgueltig'
  alias_attribute :result_corrected, 'ErgebnisKorrigiert'

  alias_attribute :weight_list_approved_at, 'WiegelisteFreigegeben'
  alias_attribute :weight_list_approved_by, 'WiegelisteFreigegebenVon'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, query_constraints: ['Regatta_ID', 'Rennen']

  belongs_to :referee_starter, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Starter", optional: true
  alias_attribute :referee_starter_id, 'Schiedsrichter_ID_Starter'

  belongs_to :referee_aligner, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Aligner", optional: true
  alias_attribute :referee_aligner_id, 'Schiedsrichter_ID_Aligner'

  belongs_to :referee_umpire, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Umpire", optional: true
  alias_attribute :referee_umpire_id, 'Schiedsrichter_ID_Umpire'

  belongs_to :referee_finish_judge, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Judge", optional: true
  alias_attribute :referee_finish_judge_id, 'Schiedsrichter_ID_Judge'

  has_many :starts, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf'],
           inverse_of: :race, dependent: :restrict_with_error
  has_many :results, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf'],
           inverse_of: :race, dependent: :restrict_with_error

  has_many :measurement_sets, query_constraints: ['Regatta_ID', 'Rennen', 'Lauf'],
           inverse_of: :race, dependent: :restrict_with_error

  scope :latest, -> do
    where.not('IstStartZeit' => nil).order('DATE(SollStartZeit) DESC, IstStartZeit DESC')
  end

  scope :upcoming, -> do
    where(arel_table['SollStartZeit'].gteq(1.hour.ago)).where('IstStartZeit' => nil).
      where("(SELECT COUNT(*) FROM #{Participant.table_name} m WHERE m.Regatta_ID = #{Race.table_name}.Regatta_ID AND m.Rennen = #{Race.table_name}.Rennen) > 1 OR (SELECT COUNT(*) FROM #{Start.table_name} s WHERE s.Regatta_ID = #{Race.table_name}.Regatta_ID AND s.Rennen = #{Race.table_name}.Rennen) > 0").
      order('SollStartZeit')
  end

  scope :for_regatta, -> (regatta) do
    where(regatta_id: regatta.id)
  end

  scope :with_results, -> do
    joins(:results).group('laeufe.Rennen, laeufe.Lauf')
  end

  scope :with_finish_times, -> do
    joins(:event, results: :times).
      where('zeiten.MesspunktNr = rennen.ZielMesspunktNr AND zeiten.Zeit IS NOT NULL')
  end

  scope :with_times_at, -> (measuring_point_number) do
    joins(:event, results: :times).
      where('zeiten.MesspunktNr = ? AND zeiten.Zeit IS NOT NULL', measuring_point_number)
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

  scope :planned_for_today, -> do
    planned_for(Date.today)
  end

  scope :planned_for, -> (date) do
    where('DATE(SollStartZeit) = ?', date.to_date)
  end

  scope :before_race, -> (race) do
    where('SollStartZeit < ?', race.planned_for).
      order('SollStartZeit DESC')
  end

  scope :following_race, -> (race) do
    where('SollStartZeit > ?', race.planned_for).
      order('SollStartZeit')
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

  def full_name(show_event_name_short: false)
    "Rennen #{event.number} #{" (#{event.name_short})" if show_event_name_short} - #{self.name}"
  end

  def type_name
    Parameter.race_type_name(self.type_short)
  end

  def result_official?
    self.result_official_since.present?
  end

  def type_short
    self.number.to_s[0]
  end

  def type_short=(s)
    if s.present?
      self.number = "#{s[0]}#{self.number.to_s[1] || 'A'}"
    else
      self.number = nil
    end
  end

  def number_short
    self.number.to_s[1]
  end

  def number_short=(s)
    if s.present?
      self.number = "#{self.number.to_s[0] || 'V'}#{s[0]}"
    else
      self.number = nil
    end
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
