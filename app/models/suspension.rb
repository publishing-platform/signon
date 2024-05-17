class Suspension
  include ActiveModel::Validations
  validates :reason_for_suspension, presence: true, if: :suspend

  attr_reader :suspend, :reason_for_suspension, :user

  def initialize(suspend: nil, reason_for_suspension: nil, user: nil)
    @suspend = suspend
    @reason_for_suspension = reason_for_suspension
    @user = user
  end

  def save
    return false unless valid?

    if suspend
      user.suspend(reason_for_suspension)
    else
      user.unsuspend
    end
  end
  alias_method :save!, :save

  def suspended?
    suspend
  end
end
