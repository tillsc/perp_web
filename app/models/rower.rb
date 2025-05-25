class Rower < ApplicationRecord

  include AliasAttributesInJson

  self.table_name = 'ruderer'

  # Transient attribute to visualize changes made to a rower. This data could be gathered by using "rower.changes"
  # before "rower.save" is made.
  attr_accessor :what_changed

  alias_attribute :id, 'ID'
  alias_attribute :first_name, 'VName'
  alias_attribute :last_name, 'NName'
  alias_attribute :year_of_birth, 'JahrG'
  alias_attribute :external_id, 'ExterneID1'
  alias_attribute :club_name, 'Zusatz'
  alias_attribute :updated_at, 'AenderungsDatum'

  alias_attribute :club_id, 'Verein_ID'
  belongs_to :club, class_name: 'Address', foreign_key: 'Verein_ID', optional: true

  has_many :weights, foreign_key: 'Ruderer_ID', dependent: :destroy

  Participant::ALL_ROWERS.each do |field|
    has_many "#{field}_in".to_sym, class_name: "Participant",
             foreign_key: field, dependent: :restrict_with_error
  end
  has_many :participants, ->(rower) {
    query = Participant::ALL_ROWERS.map { |field|
      Participant.arel_table["#{field}_id"].eq(rower.id)
    }.inject(:or)
    unscope(:where).where(query)
  }

  def self.for_regatta(regatta)
    union_sql = %w[
      ruderer1_id ruderer2_id ruderer3_id ruderer4_id
      ruderer5_id ruderer6_id ruderer7_id ruderer8_id
      ruderers_id
    ].map do |col|
      "SELECT #{col} AS ruderer_id FROM meldungen WHERE regatta_id = #{regatta.id.to_i}"
    end.join(" UNION ")

    Rower.from("(#{union_sql}) AS ruderer_in_regatta")
           .joins("JOIN ruderer ON ruderer.id = ruderer_in_regatta.ruderer_id")
           .distinct
  end

  TYPICAL_ENCODING_PROBLEMS = {'ÃŸ' => 'ß', 'Ã¼' => 'ü', 'Ãœ' => 'Ü', 'Ã©' => 'é', 'Ã¤' => 'ä', 'Ã¶' => 'ö'}
  scope :with_encoding_problems, -> {
    where(TYPICAL_ENCODING_PROBLEMS.keys.each.map do |pattern|
      arel_table[:last_name].matches("%#{pattern}%").
        or(arel_table[:first_name].matches("%#{pattern}%"))
    end.inject(:or))
  }

  scope :by_filter, -> (query) do
    query.squish.split(' ').inject(self) do |scope, word|
      if word =~ /^\d+$/
        scope.where(arel_table[:year_of_birth].matches("%#{word}"))
      else
        scope.where(arel_table[:first_name].matches("%#{word}%").or(arel_table[:last_name].matches("%#{word}%")))
      end
    end
  end

  scope :for_club, -> (club_address) do
    where(club: club_address)
  end

  # N.N.
  def self.nomen_nominandum
    Rower.find_by!(first_name: '', last_name: 'N.N.', year_of_birth: '', external_id: '')
  end

  def name(no_year_of_birth: false, no_nobr: false, is_cox: false, first_name_last_name: true)
    name = first_name_last_name ? "#{self.first_name} #{self.last_name}" : "#{self.last_name}, #{self.first_name}"
    "#{is_cox ? "St. " : ""}#{name}".tap do |s|
      s << " (#{self.year_of_birth})" if self.year_of_birth.present? && !no_year_of_birth
      s.gsub!(" ", "\u00A0") unless no_nobr
    end
  end
  def what_changed_text
    if self.what_changed&.slice("VName", "NName", "JahrG").present?
      if (visible_changes = self.what_changed&.slice("VName", "NName", "JahrG")).present?
        visible_changes.map { |k, (old, _new)| "#{k}: #{old}" }.join(", ")
      end
    end
  end

  def weight_for(date)
    self.weights.find { |w| w.date.to_date == date.to_date }
  end

  def as_json(options = nil)
    options = options.dup
    options[:methods]||= []
    options[:methods] << :name
    super(options)
  end

  def duplicates
    scope = Rower.
      where(first_name: self.first_name, last_name: self.last_name).
      where(Rower.arel_table[:id].not_eq(self.id))

    if self.year_of_birth.blank?
      scope.where(Rower.arel_table[:year_of_birth].in([nil, '']).or(
        Rower.arel_table[:club_id].eq(self.club_id))
      )
    else
      scope.where(year_of_birth: self.year_of_birth)
    end
  end

end