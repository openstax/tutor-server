require 'rails_helper'

RSpec.describe LogoutRedirectChooser do

  it "computes the CC redirect for the dev env" do
    expect(
      LogoutRedirectChooser.new("http://tutor-dev.openstax.org/blah/blah-qa").cc_redirect_url
    ).to eq "http://cc.openstax.org/logout-dev"
  end

  it "computes the CC redirect for the qa env" do
    expect(
      LogoutRedirectChooser.new("http://tutor-qa.openstax.org/blah/blah-qa").cc_redirect_url
    ).to eq "http://cc.openstax.org/logout-qa"
  end

  it "computes the CC redirect for the staging env" do
    expect(
      LogoutRedirectChooser.new("http://tutor-staging.openstax.org/blah/blah-dev").cc_redirect_url
    ).to eq "http://cc.openstax.org/logout-staging"
  end

  it "computes the CC redirect for the production env" do
    expect(
      LogoutRedirectChooser.new("http://tutor.openstax.org/blah/blah-qa").cc_redirect_url
    ).to eq "http://cc.openstax.org/logout"
  end

  it "computes the CC redirect for the localhost env" do
    expect(
      LogoutRedirectChooser.new("http://localhost:3001/blah/blah-qa").cc_redirect_url
    ).to eq "http://cc.openstax.org/logout-localhost"
  end

  it "returns the CC redirect when the request URL has conceptcoach in it" do
    expect(
      LogoutRedirectChooser.new("http://tutor.openstax.org/conCepTcoacH/blah-qa").choose
    ).to eq "http://cc.openstax.org/logout"
  end

  it "returns the CC redirect when the request URL has a truthy 'cc' param" do
    expect(
      LogoutRedirectChooser.new("http://tutor.openstax.org/yadda/blah-qa?cc=1").choose
    ).to eq "http://cc.openstax.org/logout"
  end

  it "returns the default when the request URL has a falsy 'cc' param" do
    expect(
      LogoutRedirectChooser.new("http://tutor.openstax.org/yadda/blah-qa?cc=false").choose(default: 42)
    ).to eq 42
  end

  it "returns the nil when there's no CC-ness to the URL" do
    expect(
      LogoutRedirectChooser.new("http://tutor.openstax.org/yadda/blah-qa?howdy=false").choose()
    ).to eq nil
  end

  it "returns the nil when there's no CC-ness to the URL (and no params)" do
    expect(
      LogoutRedirectChooser.new("http://tutor.openstax.org/yadda/blah-qa").choose()
    ).to eq nil
  end

end
