require 'rails_helper'

RSpec.describe Entity::Role, type: :model do
  subject(:role) { FactoryBot.create :entity_role }

  it { is_expected.to have_many(:taskings).dependent(:destroy) }

  it { is_expected.to have_one(:student).dependent(:destroy) }
  it { is_expected.to have_one(:teacher).dependent(:destroy) }

  it { is_expected.to have_one(:role_user).dependent(:destroy) }

  [:username, :first_name, :last_name, :full_name, :name].each do |delegated_method|
    it { is_expected.to delegate_method(delegated_method).to(:profile) }
  end

  it { is_expected.to validate_uniqueness_of(:research_identifier) }

  context 'research_identifier' do
    it 'is generated before save and is 9 characters long' do
      expect(role.research_identifier.length).to eq 9
    end

    it 'stays the same after multiple saves' do
      old_research_identifier = role.research_identifier
      role.updated_at = Time.now
      role.save!
      expect(role.research_identifier).to eq old_research_identifier
    end
  end

  context 'latest_enrollment_at' do
    it 'is nil if the user is not an enrolled student' do
      expect(role.latest_enrollment_at).to be_nil
    end

    it 'contains the latest enrollment date' do
      enrollment = FactoryBot.create(:course_membership_enrollment).reload
      expect(enrollment.student.role.latest_enrollment_at).to eq enrollment.created_at
    end
  end
end
