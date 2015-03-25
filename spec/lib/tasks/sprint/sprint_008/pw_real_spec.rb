require 'rails_helper'
# require 'vcr_helper'
require 'tasks/sprint/sprint_008/pw_real'

RSpec.describe Sprint008::PwReal, type: :request, 
                                  version: :v1,
                                  speed: :slow do 
                                  # vcr: VCR_OPTS 

  xit "doesn't catch on fire" do
    expect(Sprint008::PwReal.call.errors).to be_empty
  end

end
