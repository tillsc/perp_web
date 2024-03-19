class Rower < ActiveRecord::Base

  include AliasAttributesInJson

  self.table_name = 'ruderer'

  alias_attribute :id, 'ID'
  alias_attribute :first_name, 'VName'
  alias_attribute :last_name, 'NName'
  alias_attribute :year_of_birth, 'JahrG'
  alias_attribute :external_id, 'ExterneID1'
  alias_attribute :club_name, 'Zusatz'

  alias_attribute :club_id, 'Verein_ID'
  belongs_to :club, class_name: 'Address', foreign_key: 'Verein_ID', optional: true

  has_many :weights, foreign_key: 'Ruderer_ID'

  Participant::ALL_ROWERS.each do |field|
    has_many "#{field}_in".to_sym, class_name: "Participant", foreign_key: field, dependent: :restrict_with_error
  end
  has_many :participants, ->(rower) {
    query = Participant::ALL_ROWERS.map { |field|
      Participant.arel_table["#{field}_id"].eq(rower.id)
    }.inject(:or)
    unscope(:where).where(query)
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

  def name(options = {})
    "#{options[:is_cox] ? "St.\u00A0" : ""}#{self.first_name}\u00A0#{self.last_name}".tap do |s|
      s << "\u00A0(#{self.year_of_birth})" if self.year_of_birth.present?
    end
  end

  def weight_for(date)
    self.weights.find { |w| w.date.to_date == date.to_date }
  end

  def as_json(options = nil)
    options[:methods]||= []
    options[:methods] << :name
    super(options)
  end

end