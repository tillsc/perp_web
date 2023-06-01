module Internal
  class UsersController < ApplicationController

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
        redirect_to internal_users_url
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

      redirect_to internal_users_url
    end

    protected

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :role_admin)
    end

  end
end