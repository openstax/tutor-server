require 'rails_helper'
require 'vcr_helper'
require 'tasks/demo_001'

RSpec.describe Demo001, type: :request, version: :v1, speed: :slow do

  it "doesn't catch on fire" do
    expect(Demo001.call.errors).to be_empty
  end

end
