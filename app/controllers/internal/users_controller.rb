module Internal
  class UsersController < ApplicationController

    is_internal!

    def index
      authorize! :show, User

      @users = User.all
    end

    def edit
      @user = User.find(params[:id])
      authorize! :edit, @user
    end

    def update
      @user = User.find(params[:id])
      authorize! :update, @user

      if @user.update(user_params)
        flash[:info] = "Benutzer erfolgreich aktualisiert"
        redirect_to back_or_default
      else
        flash[:error] = "Benutzer konnte nicht aktualisiert werden"
        render :edit
      end
    end

    def destroy
      user = User.find(params[:id])
      authorize! :destroy, user

      if user.destroy
        flash[:info] = "Benutzer erfolgreich gelöscht"
      else
        flash[:error] = "Benutzer konnte nicht gelöscht werden"
      end

      redirect_to back_or_default
    end

    protected

    def default_url
      internal_users_url
    end

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :role_admin)
    end

  end
end