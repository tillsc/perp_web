class MyController < ApplicationController

  def index
    @noindex = true

    @address = Address.
      find_by!(public_private_id: params[:public_private_id])
    cookies[:my_public_private_id] = @address.public_private_id unless params[:no_cookie]

    @participants = if @address.is_representative?
                      @regatta.participants.where(team: @address.teams)
                    elsif @address.is_club?
                      @regatta.participants.for_club(@address)
                    end

    @participants = @participants&.preload(:team, :event, *Participant::ALL_ROWERS)

    if @participants&.any?
      @starts = Start.for_regatta(@regatta).
        upcoming.
        where(participant: @participants).
        preload(race: :event, participant: [:team] + Participant::ALL_ROWERS).
        reorder('SollStartZeit')

      @results = Result.for_regatta(@regatta).
        where(participant: @participants).
        preload(:times, race: {event: :finish_measuring_point}, participant: [:team] + Participant::ALL_ROWERS).
        joins(:race).
        reorder('IstStartZeit')
    end
  end

end