class ApplicationController < ActionController::Base

  before_action do
    if self.class.is_internal?
      authorize! :access, :internal
    end
    @regatta = Regatta.find(params[:new_regatta_id]) if params[:new_regatta_id]
    @regatta||= Regatta.find_by(id: params[:regatta_id]) if params[:regatta_id]
    @regatta||= Regatta.last
    @regattas = Regatta.valid.order(:from_date)

    if cookies[:representative_public_private_id].present?
      @representative = Address.representative.
        find_by(public_private_id: cookies[:representative_public_private_id])
    end
  end

  protected

  @is_internal_controller = false
  def self.is_internal?
    @is_internal_controller
  end

  def self.is_internal!
    @is_internal_controller = true
  end

  def default_url
    if @regatta
      regatta_url(@regatta)
    else
      root_url
    end
  end

  def after_sign_in_path_for(resource)
    params[:referrer] || internal_url(Parameter.current_regatta_id.to_s)
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
