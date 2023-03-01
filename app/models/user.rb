class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  serialize :roles, JSON

  def role_admin
    self.roles&.include?('admin')
  end

  def role_admin=(v)
    self.roles = [] unless self.roles.is_a?(Array)
    if v.present? && v != "0"
      self.roles<< 'admin' unless self.role_admin
    else
      self.roles = self.roles - ['admin']
    end
  end
end
