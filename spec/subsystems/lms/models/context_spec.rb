require 'rails_helper'

RSpec.describe Lms::Models::Context, type: :model do
  let(:context) { FactoryBot.create :lms_context }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:tool_consumer) }

  it 'finds app when it is a Lms::Models::App' do
    app = FactoryBot.create :lms_app, owner: context.course
    expect(context.app).to be_a(Lms::Models::App)
    expect(context.app).to eq app
  end

  it 'finds app when it is a Lms::WilloLabs' do
    context.update_attributes app_type: 'Lms::WilloLabs'
    expect(context.app).to be_a(Lms::WilloLabs)
  end

end
