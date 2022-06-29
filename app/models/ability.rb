# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.is_a?(::User)
      can :manage, MeasurementSet
      can :manage, MeasuringSession
    elsif user.is_a?(MeasuringSession)
      measuring_session = user
      can [:show], measuring_session
      can [:create, :update], MeasurementSet, measuring_session: measuring_session
    end
  end
end
