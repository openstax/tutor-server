require 'rails_helper'

RSpec.describe Content::Models::Map, type: :model do
  subject(:map) { FactoryBot.create :content_map }

  it { is_expected.to belong_to(:from_ecosystem) }
  it { is_expected.to belong_to(:to_ecosystem) }

  it { is_expected.to validate_uniqueness_of(:to_ecosystem).scoped_to(:content_from_ecosystem_id) }
end
