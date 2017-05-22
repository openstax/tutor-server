require 'rails_helper'

RSpec.describe OpenStax::Biglearn::Api::Job, type: :job do
  subject(:job)  { described_class.new }

  let(:course)                      { FactoryGirl.create :course_profile_course }

  let(:method)                      { :create_course }
  let(:requests)                    { [ { course: course } ] }

  let(:args)                        { { method: method, requests: requests } }

  it 'delegates #perform to a new instance of itself' do
    allow(described_class).to receive(:new).and_return(job)
    expect(job).to receive(:perform).with(args)

    described_class.perform(args)
  end

  it 'calls the Biglearn client with the given arguments' do
    expect(OpenStax::Biglearn::Api.client).to receive(method).with(requests)

    job.perform(args)
  end
end
