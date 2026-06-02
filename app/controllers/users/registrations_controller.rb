class Users::RegistrationsController < Devise::RegistrationsController
  before_action :load_address_from_ppid, only: [:new, :create]

  def new
    build_resource({})
    resource.email = @address.email if @address&.email.present?
    respond_with resource
  end

  def create
    super do |resource|
      resource.update!(address: @address) if resource.persisted? && @address
    end
  end

  private

  def load_address_from_ppid
    @ppid = params[:ppid]
    return unless @ppid.present?
    @address = Address.preload(:user).find_by!(public_private_id: @ppid)
    if @address.user.present?
      redirect_to new_user_session_path, alert: "Für diese Adresse existiert bereits ein Login."
    end
  end
end
