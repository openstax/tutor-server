require 'rails_helper'

RSpec.describe OpenStax::Accounts::Configuration do

  it 'gives the normal accounts logout URL' do
    non_cc_fake_request = OpenStruct.new(url: "http://tutor.openstax.org/madness/blah")
    expect(
      OpenStax::Accounts.configuration.logout_redirect_url(non_cc_fake_request)
    ).to eq OpenStax::Accounts.configuration.default_logout_redirect_url
  end

end
