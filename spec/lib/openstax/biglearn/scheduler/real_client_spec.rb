require 'rails_helper'
require 'vcr_helper'
require_relative 'shared_examples_for_biglearn_scheduler_clients'

RSpec.describe OpenStax::Biglearn::Scheduler::RealClient, type: :external, vcr: VCR_OPTS do
  it_behaves_like 'a biglearn scheduler client'
end
