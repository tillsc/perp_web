# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.is_a?(::User)
      can :access, :internal

      can :manage, MeasurementSet
      can :manage, MeasuringSession

      if user.role_admin
        can :manage, User
        can :manage, Address
        can :show, :measurements_history
      end


    elsif user.is_a?(MeasuringSession)
      measuring_session = user
      can [:show, :create, :update], measuring_session
      can [:create, :update], MeasurementSet, measuring_session: measuring_session
    end
  end
end
