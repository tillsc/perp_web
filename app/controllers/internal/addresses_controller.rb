module Internal
  class AddressesController < ApplicationController

    is_internal!

    def index
      authorize! :index, Address

      @addresses = Address.order_by_name.
        page(params[:page]).
        preload(:regatta_referees, :teams, :rowers)

      @addresses = @addresses.by_filter(params[:query]) if params[:query].present?

      if Address::ROLES.map(&:to_s).include?(params[:only_role])
        @addresses = @addresses.send(params[:only_role])
      elsif params[:only_role] == 'representative_current_regatta'
        @addresses = @addresses.representative_for(@regatta)
      elsif params[:only_role] == 'referee_current_regatta'
        @addresses = @addresses.referee_for(@regatta)
      end

      @all_roles = (Address::ROLES.map { |r| [Address.human_attribute_name("is_#{r}"), r.to_s] } +
        [ ['Obmann (diese Regatta)', 'representative_current_regatta'],
          ['Schiedsrichter (diese Regatta)', 'referee_current_regatta']
        ]).sort_by(&:second)

    end

    def show
      @address = Address.find(params[:id])
      authorize! :show, @address
    end

    def new
      @address = Address.new
      authorize! :new, @address
    end

    def create
      @address = Address.new(address_params)
      authorize! :create, @address

      if @address.save
        flash[:info] = helpers.success_message_for(:create, @address)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:create, @address)
        render :new
      end
    end

    def edit
      @address = Address.find(params[:id])
      authorize! :edit, @address
    end

    def update
      @address = Address.find(params[:id])
      authorize! :update, @address

      if @address.update(address_params)
        flash[:info] = helpers.success_message_for(:update, @address)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @address)
        render :edit
      end
    end

    def destroy
      address = Address.find(params[:id])
      authorize! :destroy, address

      if address.destroy
        flash[:info] = helpers.success_message_for(:destroy, address)
      else
        flash[:danger] = helpers.error_message_for(:destroy, address)
      end
      redirect_to back_or_default
    end

    def add_regatta_referee
      address = Address.find(params[:address_id])
      authorize! :update, address
      address.regatta_referees.build(regatta: @regatta)
      address.save!
      flash[:info] = "Schiedsrichter für diese Regatta hinzugefügt"
      redirect_to back_or_default
    end

    def remove_regatta_referee
      address = Address.find(params[:address_id])
      authorize! :update, address
      address.regatta_referees.where(regatta: @regatta).destroy_all
      flash[:info] = "Schiedsrichter von dieser Regatta entfernt"
      redirect_to back_or_default
    end

    protected

    def default_url
      internal_addresses_url(@regatta)
    end

    def address_params
      params.require(:address).permit(:email, :first_name, :last_name, :title, :name_suffix, :is_female, :external_id,
                                      :telefone_private, :telefone_business, :telefone_mobile, :telefone_fax,
                                      :street, :zipcode, :city, :country, :public_private_id,
                                      :is_representative, :is_club, :is_referee, :is_staff)
    end
  end
end
