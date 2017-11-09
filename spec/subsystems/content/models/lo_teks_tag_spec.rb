require 'rails_helper'

RSpec.describe Content::Models::LoTeksTag, type: :model do
  subject { FactoryBot.create :content_lo_teks_tag }

  it { is_expected.to belong_to :lo }
  it { is_expected.to belong_to :teks }

  it { is_expected.to validate_presence_of :lo }
  it { is_expected.to validate_presence_of :teks }

  it { is_expected.to validate_uniqueness_of(:teks).scoped_to(:lo_id) }
end
