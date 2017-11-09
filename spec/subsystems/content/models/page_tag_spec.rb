require 'rails_helper'

RSpec.describe Content::Models::PageTag, type: :model do
  subject { FactoryBot.create :content_page_tag }

  it { is_expected.to belong_to(:page) }
  it { is_expected.to belong_to(:tag) }

  it { is_expected.to validate_presence_of(:page) }
  it { is_expected.to validate_presence_of(:tag) }

  it { is_expected.to validate_uniqueness_of(:tag).scoped_to(:content_page_id) }
end
