require 'rails_helper'
require 'vcr_helper'
require 'tasks/sprint/sprint_010/sp'

RSpec.describe Sprint010::Sp, type: :request, version: :v1, speed: :slow, vcr: VCR_OPTS do

  it "doesn't catch on fire" do
    Sprint010::Sp.call
  end

end
