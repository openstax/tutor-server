require 'rails_helper'
require_relative 'shared_examples_for_biglearn_api_clients'

RSpec.describe OpenStax::Biglearn::Api::FakeClient, type: :external do
  it_behaves_like 'biglearn api clients'
end
