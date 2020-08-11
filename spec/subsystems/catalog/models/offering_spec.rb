require 'rails_helper'

RSpec.describe Catalog::Models::Offering, type: :model do
  subject!(:offering) { FactoryBot.create :catalog_offering }

  it { is_expected.to belong_to(:ecosystem) }

  it { is_expected.to have_many(:courses) }

  it { is_expected.to validate_presence_of(:salesforce_book_name) }
  it { is_expected.to validate_presence_of(:webview_url) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:description) }

  it 'is soft-deleted' do
    expect do
      offering.destroy!
    end.to  not_change { Catalog::Models::Offering.count }
       .and change     { offering.reload.deleted_at }.from(nil)
  end
end
