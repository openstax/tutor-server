require 'rails_helper'

RSpec.describe Content::Models::Ecosystem, type: :model do
  subject(:ecosystem) { FactoryGirl.create :content_ecosystem }

  it { is_expected.to have_many(:course_ecosystems).dependent(:destroy) }
  it { is_expected.to have_many(:courses) }

  it { is_expected.to have_many(:books).dependent(:destroy) }
  it { is_expected.to have_many(:chapters) }
  it { is_expected.to have_many(:pages) }
  it { is_expected.to have_many(:exercises) }
  it { is_expected.to have_many(:pools) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:archive_url) }
end
