# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.is_a?(::User)
      can :access, :internal

      if user.role_timekeeping || user.role_admin
        can :manage, MeasurementSet
        can :manage, MeasuringSession
        can :manage, :measurements_history
      end

      if user.role_weighing || user.role_admin
        can :manage, Weight
      end

      if user.role_registration || user.role_admin
        can :manage, Participant
        can :manage, Team
        can :manage, Rower
      end

      if user.role_admin
        can :manage, User
        can :manage, Address
        can :manage, Event
        can :manage, Race
        can :manage, MeasuringPoint
        can :manage, :tv_settings
        can :manage, Regatta
        cannot :delete, Regatta do |r|
          r.events.any?
        end
      end


    elsif user.is_a?(MeasuringSession)
      measuring_session = user
      can [:show, :create, :update], measuring_session
      can [:create, :update], MeasurementSet, measuring_session: measuring_session
    end
  end
end
