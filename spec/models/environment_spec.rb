require 'rails_helper'

RSpec.describe Environment, type: :model do
  subject(:environment) { FactoryBot.create :environment }

  it { is_expected.to validate_presence_of(:name)   }
  it { is_expected.to validate_uniqueness_of(:name) }

  it 'can return the current environment' do
    expect(Environment.current.name).to eq Rails.application.secrets.environment_name
  end

  it 'knows if it is the current environment' do
    expect(Environment.current.current?).to eq true
    expect(FactoryBot.create(:environment).current?).to eq false
  end
end
