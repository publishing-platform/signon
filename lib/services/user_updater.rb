module Services
  class UserUpdater < ApplicationService
    def initialize(user, user_params, current_user)
      super()
      @user = user
      @user_params = user_params
      @current_user = current_user
    end

    def call
      @user.skip_reconfirmation!
      return unless update_user

      if @user.previous_changes[:email] && (@user.web_user? && @user.invited_but_not_yet_accepted?)
        @user.invite!
      end

      true
    end

  private

    def filtered_user_params
      @user_params
    end

    def update_user
      @user.update(filtered_user_params)
    end
  end
end
