module Public
  class UserSessionsController < ApplicationController

    before_filter :require_user, :only => :sign_out
    before_filter :set_navs

    layout 'sign_in'

    def sign_in
      redirect_to_appropriate_page_after_sign_in if @current_user
    end

    ## This method will accept a proc, execute it and render the json
    def create_session

      # Fetching the user data (email / username is case insensitive.)
      @user = User.where("LOWER(email) = LOWER('#{params['email']}')").first

      # If the user exists with the given username / password
      if @user
        # Check if the user is not approved (pending, locked or blocked)
        # Will allow to login only if status is approved
        if @user.status != ConfigCenter::User::APPROVED

          puts "#{@user.email} id not approved".yellow

          @heading = translate("authentication.error")
          @alert = translate("authentication.user_is_#{@user.status.downcase}")
          store_flash_message("#{@heading}: #{@alert}", :error)
          redirect_after_unsuccessful_authentication
          return

        # Check if the password matches
        # Invalid Login: Password / Username doesn't match
        elsif @user.authenticate(params['password']) == false

          puts "#{@user.email} not authenticated".yellow

          @heading = translate("authentication.error")
          @alert = translate("authentication.invalid_login")
          store_flash_message("#{@heading}: #{@alert}", :error)
          redirect_after_unsuccessful_authentication
          return
        end

        puts "#{@user.email} logged in".yellow

        # If successfully authenticated.
        @heading = translate("authentication.success")
        @alert = translate("authentication.logged_in_successfully")
        store_flash_message("#{@heading}: #{@alert}", :success)
        session[:id] = @user.id
        redirect_to_appropriate_page_after_sign_in

      # If the user with provided email doesn't exist
      else

        puts "#{params['email']} not found".yellow

        @heading = translate("authentication.error")
        @alert = translate("authentication.user_not_found")
        store_flash_message("#{@heading}: #{@alert}", :error)
        redirect_after_unsuccessful_authentication

      end

    end

    def sign_out

      @heading = translate("authentication.success")
      @alert = translate("authentication.logged_out_successfully")
      store_flash_message("#{@heading}: #{@alert}", :notice)

      # Reseting the auth token for user when he logs out.
      @current_user.update_attribute :auth_token, SecureRandom.hex

      session.delete(:id)
      restore_last_user
      redirect_after_unsuccessful_authentication

    end

    private

    def set_navs
      set_nav("Login")
    end

  end
end
