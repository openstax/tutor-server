require 'rails_helper'

RSpec.describe ::TimeZone, type: :model do
  subject(:time_zone) { FactoryBot.create :time_zone }

  it { is_expected.to have_one(:course) }
  it { is_expected.to have_many(:tasking_plans) }
  it { is_expected.to have_many(:tasks) }

  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_inclusion_of(:name)
                        .in_array(ActiveSupport::TimeZone.all.map(&:name)) }

  it 'can be converted to an ActiveSupport::TimeZone' do
    expect(time_zone.to_tz).to eq ActiveSupport::TimeZone['Central Time (US & Canada)']
  end
end
