# frozen_string_literal: true

module Users
  # nodoc
  class SessionsController < Devise::SessionsController
    include ActionController::Cookies

    # Devise automatically performs a require_no_authentication method that
    # uses flash messages, which are disabled in Rails API mode.
    # We skip this step for the create method.
    skip_before_action :require_no_authentication, only: [:create]

    # Dont sanitize anything, just for the demo.
    # before_action :configure_sign_in_params, only: [:create]

    # Quick error rescue for simplicity.
    # Rescue from specific errors in a real application.
    rescue_from StandardError do |exception|
      render status: :unauthorized
      Rails.logger.error exception.message
    end

    # POST /resource/sign_in
    def create
      sign_out if user_signed_in?
      # Dont check any password to simplify things.
      @user = User.find_by!(email: params[:email])
      sign_in @user
      render status: :ok
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
