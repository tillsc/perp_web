class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def to_anchor
    "#{self.class.name.underscore}_#{self.to_param}"
  end
end
