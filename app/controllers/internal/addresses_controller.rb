module Internal
  class AddressesController < ApplicationController

    def index
      authorize! :index, Address

      @addresses = Address.order_by_name.representative_for(@regatta)
    end

    def edit
      @address = Address.find(params[:id])
      authorize! :edit, @address
    end

    def update
      @address = Address.find(params[:id])
      authorize! :update, @address

      if @address.update(address_params)
        flash[:info] = "Benutzer erfolgreich aktualisiert"
        redirect_to internal_addresses_url(@regatta)
      else
        flash[:error] = "Benutzer konnte nicht aktualisiert werden"
        render :edit
      end
    end

    protected

    def address_params
      params.require(:address).permit(:email, :first_name, :last_name)
    end
  end
end
