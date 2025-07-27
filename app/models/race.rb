class Race < ApplicationRecord

  self.table_name = 'laeufe'
  self.primary_key = 'Regatta_ID', 'Rennen', 'Lauf'

  include HasRaceNumber
  self.race_number_field = :number

  alias_attribute :regatta_id, 'Regatta_ID'
  alias_attribute :number, 'Lauf'
  alias_attribute :event_number, 'Rennen'
  alias_attribute :started_at_time, 'IstStartZeit'
  alias_attribute :planned_for, 'SollStartZeit'

  alias_attribute :result_confirmed_since, 'ErgebnisBestaetigt'
  alias_attribute :result_official_since, 'ErgebnisEndgueltig'
  alias_attribute :result_corrected, 'ErgebnisKorrigiert'

  alias_attribute :weight_list_approved_at, 'WiegelisteFreigegeben'
  alias_attribute :weight_list_approved_by, 'WiegelisteFreigegebenVon'

  belongs_to :regatta, foreign_key: 'Regatta_ID'
  belongs_to :event, foreign_key: ['Regatta_ID', 'Rennen']

  belongs_to :referee_starter, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Starter", optional: true
  alias_attribute :referee_starter_id, 'Schiedsrichter_ID_Starter'

  belongs_to :referee_aligner, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Aligner", optional: true
  alias_attribute :referee_aligner_id, 'Schiedsrichter_ID_Aligner'

  belongs_to :referee_umpire, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Umpire", optional: true
  alias_attribute :referee_umpire_id, 'Schiedsrichter_ID_Umpire'

  belongs_to :referee_finish_judge, class_name: 'Address', foreign_key: "Schiedsrichter_ID_Judge", optional: true
  alias_attribute :referee_finish_judge_id, 'Schiedsrichter_ID_Judge'

  has_many :starts, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf'],
           inverse_of: :race, dependent: :restrict_with_error
  has_many :results, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf'],
           inverse_of: :race, dependent: :restrict_with_error

  has_many :measurement_sets, foreign_key: ['Regatta_ID', 'Rennen', 'Lauf'],
           inverse_of: :race, dependent: :restrict_with_error

  scope :order_by_started_at, -> (asc: true) do
    order(Arel.sql(%Q(DATE("SollStartZeit") #{asc ? "ASC" : "DESC"})),
          arel_table[:started_at_time].send(asc ? :asc : :desc))
  end

  scope :order_by_planned_for, -> (asc: true) do
    order(arel_table[:planned_for].send(asc ? :asc : :desc))
  end

  scope :latest, -> do
    where.not(arel_table[:started_at_time].eq(nil)).
      order_by_started_at(asc: false)
  end

  scope :upcoming, -> do
    participants = Participant.arel_table.
      project(Arel.star.count).
      where(Participant.arel_table[:Regatta_ID].eq(arel_table[:Regatta_ID]).
        and(Participant.arel_table[:Rennen].eq(arel_table[:Rennen])))

    starts = Start.arel_table.
      project(Arel.star.count).
      where(Start.arel_table[:Regatta_ID].eq(arel_table[:Regatta_ID]).
        and(Start.arel_table[:Rennen].eq(arel_table[:Rennen])))

    where(arel_table[:planned_for].gteq(1.hour.ago)).
      where(arel_table[:started_at_time].eq(nil)).
      where(Arel::Nodes::SqlLiteral.new("(#{participants.to_sql})").gt(1).or(Arel::Nodes::SqlLiteral.new("(#{starts.to_sql})").gt(0))).
      order_by_planned_for
  end

  scope :for_regatta, -> (regatta) do
    where(regatta_id: regatta.id)
  end

  scope :with_results, -> do
    with_existing(:results)
  end

  scope :with_finish_times, -> do
    with_times_at(Event.arel_table[:finish_measuring_point_number])
  end

  scope :with_times_at, -> (measuring_point_number) do
    joins(:event, results: :times).
      where(ResultTime.arel_table[:measuring_point_number].eq(measuring_point_number)).
      where(ResultTime.arel_table[:time].not_eq(:nil))
  end

  scope :with_starts, -> do
    with_existing(:starts)
  end

  scope :now, -> do
    stated_minutes_ago(12)
  end

  scope :nearby, -> do
    where(arel_table[:planned_for].between((20.minutes.ago)..(20.minutes.since)))
  end

  scope :stated_minutes_ago, -> (minutes) do
    where(arel_table[:started_at_time].between((minutes.minutes.ago)..(Time.current.getlocal))).
      where(planned_for: Date.today.all_day).
      order_by_started_at
  end

  scope :planned_for_today, -> do
    planned_for(Date.today)
  end

  scope :planned_for, ->(date) do
    where(planned_for: date.all_day)
  end

  scope :before_race, -> (race) do
    where(arel_table[:planned_for].lt(race.planned_for)).
      order_by_planned_for(asc: false)
  end

  scope :following_race, -> (race) do
    where(arel_table[:planned_for].gt(race.planned_for)).
      order_by_planned_for
  end

  scope :current_start, -> do
    where(arel_table[:started_at_time].eq(nil).or(
      arel_table[:started_at_time].gt(2.minutes.ago)
    )).
      where(planned_for: Date.today.all_day).
      order(arel_table[:planned_for].asc, arel_table[:started_at_time].desc)
  end

  def name
    "#{Parameter.race_type_name(self.type_short)} #{self.number_short}"
  end

  def full_name(show_event_name_short: false)
    "Rennen #{event&.number} #{" (#{event&.name_short})" if show_event_name_short} - #{self.name}"
  end

  def type_name
    Parameter.race_type_name(self.type_short)
  end

  def result_confirmed?
    self.result_confirmed_since.present? ||
      self.result_official?
  end

  def result_official?
    self.result_official_since.present?
  end

  def state_text
    if result_official?
      "Ergebnis endgültig#{ '(Ergebnis korrigiert)' if result_corrected?}"
    elsif result_confirmed?
      'Ergebnis vom Zielrichter freigegeben'
    else
      'Ergebnis vorläufig'
    end
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
