require 'rails_helper'
require 'vcr_helper'
require 'tasks/sprint/sprint_009/sp'

RSpec.describe Sprint009::Sp, type: :request, version: :v1, speed: :slow, vcr: VCR_OPTS do

  it "doesn't catch on fire" do
    Sprint009::Sp.call
  end

end
