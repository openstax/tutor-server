require 'rails_helper'
require 'vcr_helper'
require_relative 'shared_examples_for_biglearn_api_clients'

RSpec.describe OpenStax::Biglearn::Api::RealClient, type: :external, vcr: VCR_OPTS do
  it_behaves_like 'a biglearn api client'
end
