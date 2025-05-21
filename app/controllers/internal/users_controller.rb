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
        flash[:info] = helpers.success_message_for(:update, @user)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @user)
        render :edit
      end
    end

    def destroy
      user = User.find(params[:id])
      authorize! :destroy, user

      if user.destroy
        flash[:info] = helpers.success_message_for(:destroy, user)
      else
        flash[:danger] =  helpers.error_message_for(:destroy, user)
      end

      redirect_to back_or_default
    end

    protected

    def default_url
      internal_users_url
    end

    def user_params
      params.require(:user).permit(:email, :highlight_nobr, :password, :password_confirmation, *User::ALL_ROLES.map { |r| "role_#{r}".to_sym })
    end

  end
end