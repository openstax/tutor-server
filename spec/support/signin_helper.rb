module SigninHelper
  def stub_oauth_sign_in
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!) { true }
  end
end
