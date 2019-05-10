require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Biglearn::Api::Client, type: :external, vcr: VCR_OPTS do
  subject(:client)       { OpenStax::Biglearn::Api::Client.new }

  let(:preparation_uuid) { SecureRandom.uuid }
  let(:course)           { FactoryBot.create(:course_profile_course) }
  let(:ecosystem)        { FactoryBot.create(:content_ecosystem) }

  let(:req)              do
    { preparation_uuid: preparation_uuid, course: course, ecosystem: ecosystem }
  end

  it 'can call prepare_course_ecosystem and update_course_ecosystems sequentially' do
    expect(client).to receive(:prepare_course_ecosystem).with(req)
    expect(OpenStax::Biglearn::Api).to receive(:update_course_ecosystems).with(
      req.slice(:course, :preparation_uuid)
    )
    client.sequentially_prepare_and_update_course_ecosystem req
  end
end
