require 'rails_helper'
require 'vcr_helper'
require 'tasks/sprint/sprint_007_a/main'

RSpec.describe Sprint007A::Main, :type => :request, version: :v1, vcr: VCR_OPTS do

  it "doesn't catch on fire" do
    expect(Sprint007A::Main.call.errors).to be_empty
  end

end
