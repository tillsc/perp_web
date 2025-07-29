class ApplicationController < ActionController::Base

  before_action do
    if self.class.is_internal?
      authorize! :access, :internal
    end
    @regatta = Regatta.find(params[:new_regatta_id]) if params[:new_regatta_id]
    @regatta||= Regatta.find_by(id: params[:regatta_id]) if params[:regatta_id]
    @regatta||= Regatta.last
    @regattas = Regatta.valid.order(:from_date)

    if cookies[:my_public_private_id].present?
      @my_address = Address.
        find_by(public_private_id: cookies[:my_public_private_id])
    end

    self.class.layout params[:_layout] == "false" ? "minimal" : nil
  end

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound do |exception|
    if params[:new_regatta_id]
      if self.class.is_internal?
        redirect_to internal_path(params[:new_regatta_id])
      else
        redirect_to regatta_path(params[:new_regatta_id])
      end
    else
      raise exception
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

  def dom_id(*args)
    ActionView::RecordIdentifier.dom_id(*args)
  end

  def back_or_default_with_uri_params(default: nil, **additional_uri_params)
    uri = URI.parse(back_or_default(default).to_s)
    all_params = Hash[URI.decode_www_form(String(uri.query))].merge(additional_uri_params)
    uri.query = URI.encode_www_form(all_params)
    uri.to_s
  end

  def after_sign_in_path_for(resource)
    regatta_id = Parameter.current_regatta_id.to_s.presence
    params[:referrer] || (regatta_id && internal_url(regatta_id)) || internal_regattas_url
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

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:highlight_nobr])
  end

end
