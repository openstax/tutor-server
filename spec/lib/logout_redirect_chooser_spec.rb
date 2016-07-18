require 'rails_helper'

RSpec.describe LogoutRedirectChooser, type: :lib do

  let(:default) { "http://accounts.openstax.org/logout/" }
  let(:cc_logout) { default + "?cc=1" }

  def choose_for(url)
    LogoutRedirectChooser.new(url).choose(default: default)
  end

  it "returns the CC redirect when the request URL has conceptcoach in it" do
    expect(choose_for("http://tutor.openstax.org/conCepTcoacH/blah-qa")).to eq cc_logout
  end

  it "returns the CC redirect when the request URL has a truthy 'cc' param" do
    expect(choose_for("http://tutor.openstax.org/yadda/blah-qa?cc=1")).to eq cc_logout
  end

  it "returns the default when the request URL has a falsy 'cc' param" do
    expect(choose_for("http://tutor.openstax.org/yadda/blah-qa?cc=false")).to eq default
  end

  it "returns the default when there's no CC-ness to the URL" do
    expect(choose_for("http://tutor.openstax.org/yadda/blah-qa?howdy=false")).to eq default
  end

  it "returns the default when there's no CC-ness to the URL (and no params)" do
    expect(choose_for("http://tutor.openstax.org/yadda/blah-qa")).to eq default
  end

end
