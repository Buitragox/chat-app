# frozen_string_literal: true

module Users
  # nodoc
  class SessionsController < Devise::SessionsController
    include ActionController::Cookies

    # Devise automatically performs a require_no_authentication method that
    # uses flash messages, which are disabled in API mode.
    # We skip this step for the create method.
    skip_before_action :require_no_authentication, only: [:create]

    # Dont sanitize anything, just for the demo.
    # before_action :configure_sign_in_params, only: [:create]

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    def create
      sign_out if user_signed_in?

      # Dont check any password to simplify things.
      @user = User.find_by(email: params[:email])
      if @user
        sign_in @user
        render status: :ok
      else
        render status: :unauthorized
      end
    end

    # DELETE /resource/sign_out
    def destroy
      sign_out
    end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end

  end
end
