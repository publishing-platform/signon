class SuspensionsController < ApplicationController
  before_action :authenticate_user!, :load_and_authorize_user

  def edit
    @suspension = Suspension.new(suspend: @user.suspended?,
                                 reason_for_suspension: @user.reason_for_suspension)
  end

  def update
    @suspension = Suspension.new(suspend: params[:user][:suspended] == "1",
                                 reason_for_suspension: params[:user][:reason_for_suspension],
                                 user: @user)

    if @suspension.save
      notice = "#{@user.email} is now #{@user.suspended? ? 'suspended' : 'active'}."

      redirect_to @user.api_user? ? edit_api_user_path(@user) : edit_user_path(@user), notice:
    else
      render :edit
    end
  end

private

  def load_and_authorize_user
    @user = User.find(params[:user_id])
    authorize @user, :suspension?
  end
end
