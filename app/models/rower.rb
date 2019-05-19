class Rower < ActiveRecord::Base

  self.table_name = 'ruderer'

  alias_attribute :first_name, 'VName'
  alias_attribute :last_name, 'NName'
  alias_attribute :year_of_birth, 'JahrG'

  def name(options = {})
    "#{options[:is_cox] ? "St.\u00A0" : ""}#{self.first_name}\u00A0#{self.last_name}".tap do |s|
      s << "\u00A0(#{self.year_of_birth})"
    end
  end

end