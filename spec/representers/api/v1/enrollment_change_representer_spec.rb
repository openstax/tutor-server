require 'rails_helper'

RSpec.describe Api::V1::EnrollmentChangeRepresenter, type: :representer do
  let(:user)              do
    profile = FactoryBot.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let(:course)            { FactoryBot.create :course_profile_course }
  let(:period_1)          { FactoryBot.create :course_membership_period, course: course }
  let(:period_2)          { FactoryBot.create :course_membership_period, course: course }

  let(:teacher_user)      { FactoryBot.create(:user) }
  let!(:teacher_role)     { AddUserAsCourseTeacher[user: teacher_user, course: course] }

  let(:enrollment_change) { CourseMembership::CreateEnrollmentChange[
    user: user, enrollment_code: period_2.enrollment_code, requires_enrollee_approval: false
  ] }

  let(:representation)    { described_class.new(enrollment_change).as_json }

  before                  { AddUserAsPeriodStudent[user: user, period: period_1] }

  it 'represents an enrollment change request' do
    expect(representation['id']).to eq enrollment_change.id.to_s
    expect(representation['from']['course']['id']).to eq course.id.to_s
    expect(representation['from']['course']['name']).to eq course.name
    expect(representation['from']['period']['id']).to eq period_1.id.to_s
    expect(representation['from']['period']['name']).to eq period_1.name
    expect(representation['to']['course']['id']).to eq course.id.to_s
    expect(representation['to']['course']['name']).to eq course.name
    expect(representation['to']['period']['id']).to eq period_2.id.to_s
    expect(representation['to']['period']['name']).to eq period_2.name
    expect(representation['to']['period']['is_lms_enabled']).to eq course.is_lms_enabled
    expect(representation['status']).to eq enrollment_change.status.to_s
    expect(representation['requires_enrollee_approval']).to eq false
  end

  it 'includes teacher names in enrollment change' do
    expect(representation['to']['course']['teachers']).to eq [{
      'name' => teacher_role.name,
      'first_name' => teacher_role.first_name,
      'last_name'  => teacher_role.last_name
    }]
  end

  it 'does not include archived periods as "from"' do
    # If a "from" period is included in the output, the FE will display it as a transfer
    # If the previous period is archived, then the enrollment should be considered a fresh join
    period_1.to_model.destroy
    expect(representation['from']).to be_nil
  end
end
