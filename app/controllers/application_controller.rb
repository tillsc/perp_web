class ApplicationController < ActionController::Base

  before_action do
    @regatta = Regatta.find(params[:regatta_id]) if params[:regatta_id]
    @regattas = Regatta.valid

    if cookies[:representative_public_private_id].present?
      @representative = Address.representative.
        find_by(public_private_id: cookies[:representative_public_private_id])
    end
  end

  def current_user
    super || @measuring_session
  end

end
