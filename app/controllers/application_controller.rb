class ApplicationController < ActionController::Base

  before_action do
    @regatta = Regatta.find(params[:regatta_id]) if params[:regatta_id]
    @regattas = Regatta.valid

    if cookies[:representative_public_private_id].present?
      @representative = Address.representative.
        find_by(public_private_id: cookies[:representative_public_private_id])
    end
  end

  protected

  def after_sign_in_path_for(resource)
    params[:referrer] || internal_url
  end


  rescue_from CanCan::AccessDenied do |exception|
    if !current_user
      redirect_to new_user_session_url(referrer: request.original_url)
    else
      raise exception
    end
  end

  def current_user
    super || @measuring_session
  end

end
