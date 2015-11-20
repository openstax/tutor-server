require 'rails_helper'

RSpec.describe OpenStax::Accounts::Configuration do

  it 'gives a the normal accounts logout URL when the request does NOT comes from CC' do
    non_cc_fake_request = OpenStruct.new(url: "http://tutor.openstax.org/madness/blah")
    expect(
      OpenStax::Accounts.configuration.logout_redirect_url(non_cc_fake_request)
    ).to eq OpenStax::Accounts.configuration.default_logout_redirect_url
  end

  it 'gives a concept coach logout URL when the request comes from CC' do
    cc_fake_request = OpenStruct.new(url: "http://tutor.openstax.org/ConCEptCoach/blah")
    expect(
      OpenStax::Accounts.configuration.logout_redirect_url(cc_fake_request)
    ).to eq OpenStax::Accounts.configuration.default_logout_redirect_url + "?cc=1"
  end

end
