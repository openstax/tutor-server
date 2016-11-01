require 'rails_helper'

RSpec.describe User::Models::TourView, type: :model do

  let(:tour) {FactoryGirl.create(:user_tour)}
  let(:profile) { FactoryGirl.create(:user_profile) }
  subject(:tour_view) {
    ::User::Models::TourView.create(tour: tour, profile: profile)
  }
  it { is_expected.to belong_to(:profile) }
  it { is_expected.to belong_to(:tour) }
  it { is_expected.to validate_presence_of(:profile) }
  it { is_expected.to validate_presence_of(:tour) }
  it { is_expected.to validate_presence_of(:view_count) }
  it { is_expected.to(validate_uniqueness_of(:tour).scoped_to(:user_profile_id)) }

end
