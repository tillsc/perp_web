class Address < ApplicationRecord

  self.table_name = 'addressen'

  alias_attribute :title, 'Titel'
  alias_attribute :first_name, 'Vorname'
  alias_attribute :last_name, 'Name'
  validates :last_name, presence: true
  alias_attribute :name_suffix, 'Namenszusatz'
  alias_attribute :is_female, 'Weiblich'

  alias_attribute :external_id, 'ExterneID1'

  alias_attribute :street, 'Strasse'
  alias_attribute :zipcode, 'PLZ'
  alias_attribute :city, 'Ort'
  alias_attribute :country, 'Land'

  alias_attribute :telefone_private, "Telefon_Privat"
  alias_attribute :telefone_business, "Telefon_Geschaeftlich"
  alias_attribute :telefone_mobile, "Telefon_Mobil"
  alias_attribute :telefone_fax, "Fax"

  alias_attribute :email, 'eMail'

  ROLES = [:representative, :club, :referee, :staff].freeze
  alias_attribute :is_representative, 'IstObmann'
  alias_attribute :is_club, 'IstVerein'
  alias_attribute :is_referee, 'IstSchiedsrichter'
  alias_attribute :is_staff, 'IstRegattastab'
  validate do
    unless ROLES.any? { |r| self.send("is_#{r}?") }
      ROLES.each do |r|
        self.errors.add("is_#{r}", :select_at_least_one)
      end
    end
  end

  alias_attribute :public_private_id, 'PublicPrivateID'
  validates :public_private_id, uniqueness: true

  has_many :teams, foreign_key: 'Obmann_ID'
  has_many :rowers, foreign_key: 'Verein_ID'

  has_many :regatta_referees, foreign_key: 'Schiedsrichter_ID'

  ROLES.each do |role_name|
    scope role_name, -> do
      where("is_#{role_name}": true)
    end
  end

  scope :by_filter, -> (query) do
    query.squish.split(' ').inject(self) do |scope, word|
      scope.where(arel_table[:first_name].matches("%#{word}%").or(arel_table[:last_name].matches("%#{word}%")))
    end
  end

  scope :representative_for, -> (regatta) do
    where(teams: Team.for_regatta(regatta))
  end

  scope :referee_for, -> (regatta) do
    joins(:regatta_referees).
      where('schiedsrichterliste.Regatta_ID' => regatta)
  end

  scope :order_by_name, -> do
    order(:last_name, :first_name)
  end

  scope :order_existing_first, -> (regatta) do
    order(Arel.sql('EXISTS (SELECT 1 FROM teams t WHERE t.obmann_id = addressen.id AND t.regatta_id = :regatta_id) DESC', regatta_id: regatta.id)).
      order_by_name
  end

  def name
    if is_club?
      last_name.presence || first_name.presence
    else
      [last_name.presence, first_name.presence].compact.join(', ')
    end
  end

  def referee_for?(regatta)
    self.regatta_referees.any? { |rr| rr.regatta_id == regatta.id }
  end

  def status_label
    ROLES.map { |role_name|
      if self.send("is_#{role_name}?")
        Address.human_attribute_name("is_#{role_name}")
      else
        nil
      end
    }.compact.join(', ')
  end

  def deletable?
    rowers.none? && regatta_referees.none? && teams.none?
  end

end