require 'rails_helper'

RSpec.describe GetTeacherNames, type: :routine do
  let(:course) { Entity::Course.create! }
  let(:teacher) {
    profile = FactoryGirl.create(:user_profile,
                                 first_name: 'Teacher',
                                 last_name: 'Jim')
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let(:other_teacher) {
    profile = FactoryGirl.create(:user_profile,
                                 first_name: 'Teacher',
                                 last_name: 'Bob')
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:not_teacher) {
    profile = FactoryGirl.create(:user_profile,
                                 first_name: 'Somebody',
                                 last_name: 'Else')
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  before do
    AddUserAsCourseTeacher[course: course, user: teacher]
    AddUserAsCourseTeacher[course: course, user: other_teacher]
  end

  subject(:names) { described_class[course.id] }

  it { should include('Teacher Jim') }
  it { should include('Teacher Bob') }
  it { should_not include('Somebody Else') }
end
