# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.is_a?(::User)
      can :access, :internal

      if user.roles.any?
        can :access, :announcer_views
        can :read, [Rower, Result, Start, Participant, Team, Event, Race, Address, Services::TimeSchedule::Block]
      end

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
        cannot :fast_edit, Participant do |participant|
          participant.imported_from.present?
        end
        can :manage, Import
        cannot :execute, Import do |i|
          i.imported_at.present?
        end
        can :manage, Team
        can [:read, :create], Rower
        can [:read, :cteate, :edit], Address
        can :read, [Event, Race]
      end

      if user.role_admin
        can :manage, User
        can :manage, [Address, Rower, Event, Race, Start, Result, ExternalMeasurement]
        can :update, Services::TimeSchedule::Block do |block|
          block.all_races.all? { |race| can?(:update, race) }
        end
        can :manage, MeasuringPoint
        can :manage, :tv_settings
        can :read, [:statistics, :server_status, :reports]
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
