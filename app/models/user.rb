class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  serialize :roles, coder: JSON

  ALL_ROLES = [:admin, :weighing, :registration, :timekeeping, :announcer]

  ALL_ROLES.each do |role|
    define_method "role_#{role}" do
      self.roles&.include?(role.to_s)
    end

    define_method "role_#{role}=" do |v|
      self.roles = [] unless self.roles.is_a?(Array)
      if v.present? && v != "0"
        self.roles << role.to_s unless self.send("role_#{role}")
      else
        self.roles = self.roles - [role.to_s]
      end
    end
  end
end
