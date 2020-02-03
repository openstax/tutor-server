require 'rails_helper'

RSpec.describe Content::ListEcosystems, type: :routine do
  let!(:ecosystem_1)       { FactoryBot.create(:content_ecosystem) }
  let!(:ecosystem_2)       { FactoryBot.create(:content_ecosystem) }
  let!(:deleted_ecosystem) { FactoryBot.create(:content_ecosystem).tap { |eco| eco.destroy } }

  it 'returns all non-deleted ecosystems' do
    expect(described_class.call.outputs.ecosystems).to match_array [ ecosystem_1, ecosystem_2 ]
  end
end
