require 'rails_helper'

RSpec.describe OpenStax::Accounts::Configuration do
  let(:profile) { FactoryBot.create(:user_profile) }
  let(:controller) {
    c=OpenStruct.new(
      main_app: OpenStruct.new(root_url: '/root'),
      request: OpenStruct.new(
        url: "http://tutor.openstax.org/madness/blah",
        session: {}
      )
    )
    def c.sign_out!; end
    def c.redirect_to(_); end
    c
  }

  it 'gives a the normal accounts logout URL' do
    expect(controller).to receive(:redirect_to).with('/root')
    expect(controller).to receive(:sign_out!)
    OpenStax::Accounts.configuration.logout_handler.call(controller)
  end

  it 'redirects when admin is impersonating a user' do
    controller.request.session[:admin_user_id] = profile.id
    expect(controller).to receive(:redirect_to).with('/admin/users')
    OpenStax::Accounts.configuration.logout_handler.call(controller)
    expect(controller.request.session[:admin_user_id]).to be_nil
    expect(controller.request.session[:account_id]).to eq profile.account_id
  end
end
