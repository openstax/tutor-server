require 'rails_helper'

RSpec.describe Content::Models::Page, type: :model do
  subject { FactoryGirl.create :content_page }

  it { is_expected.to belong_to(:chapter) }
  it { is_expected.to validate_presence_of(:title) }
end
