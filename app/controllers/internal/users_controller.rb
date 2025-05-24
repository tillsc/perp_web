module Internal
  class UsersController < ApplicationController

    is_internal!

    def index
      authorize! :show, User

      @users = User.all
    end

    def new
      authorize! :new, User

      @user = User.new
    end

    def create
      authorize! :create, User

      @user = User.new(user_params)
      if @user.save
        flash[:info] = helpers.success_message_for(:create, @user)
        redirect_to back_or_default_with_uri_params(dialog_finished_with: @user.id)
      else
        flash[:danger] = helpers.error_message_for(:create, @user)
        render :new
      end
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
      params.require(:user).
        permit(:email, :password, :password_confirmation,
               :confirmed_at, :highlight_nobr,
               *User::ALL_ROLES.map { |r| "role_#{r}".to_sym }).
        reject { |k, v| k.start_with?("password") && v.blank? }
    end

  end
end