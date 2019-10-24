require 'rails_helper'
require_relative 'shared_examples_for_biglearn_scheduler_clients'

RSpec.describe OpenStax::Biglearn::Scheduler::FakeClient, type: :external do
  it_behaves_like 'a biglearn scheduler client'
end
