module SigninHelper
  def stub_current_user(user, recipient=ApplicationController)
    allow_any_instance_of(recipient)
      .to receive(:current_account)
      .and_return(user.account) if recipient.method_defined?(:current_account)

    allow_any_instance_of(recipient)
      .to receive(:current_user)
      .and_return(user) if recipient.method_defined?(:current_user)

    allow_any_instance_of(recipient)
      .to receive(:current_human_user)
      .and_return(user) if recipient.method_defined?(:current_human_user)
  end

  def unstub_current_user(recipient=ApplicationController)
    allow_any_instance_of(recipient)
      .to receive(:current_account)
      .and_call_original if recipient.method_defined?(:current_account)

    allow_any_instance_of(recipient)
      .to receive(:current_user)
      .and_call_original if recipient.method_defined?(:current_user)

    allow_any_instance_of(recipient)
      .to receive(:current_human_user)
      .and_call_original if recipient.method_defined?(:current_human_user)
  end
end
