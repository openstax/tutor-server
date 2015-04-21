require 'rails_helper'
require 'vcr_helper'
require 'tasks/sprint/sprint_010/events'

RSpec.describe Sprint010::Events, type: :request, version: :v1, speed: :slow, vcr: VCR_OPTS do

  it "doesn't catch on fire" do
    Sprint010::Events.call
  end

end
