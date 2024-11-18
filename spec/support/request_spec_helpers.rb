module RequestSpecHelper
  include Warden::Test::Helpers

  def self.included(base)
    base.before { Warden.test_mode! }
    base.after { Warden.test_reset! }
  end

  def sign_in(resource, require_2fa: false)
    resource.update!(require_2fa:)
    login_as(resource, scope: warden_scope(resource))
  end

  def sign_out(resource)
    logout(warden_scope(resource))
  end

  def assert_not_authenticated
    expect(response).to redirect_to(new_user_session_path)
  end

  def assert_not_authorised
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("You do not have permission to perform this action.")
  end

private

  def warden_scope(resource)
    resource.class.name.underscore.to_sym
  end
end
