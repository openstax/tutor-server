require 'rails_helper'

RSpec.describe GetTeacherNames, type: :routine do
  let(:course) { Entity::Course.create! }
  let(:teacher) { FactoryGirl.create(:user, first_name: 'Teacher', last_name: 'Jim') }
  let(:other_teacher) { FactoryGirl.create(:user, first_name: 'Teacher',
                                                  last_name: 'Bob') }
  let!(:not_teacher) { FactoryGirl.create(:user, first_name: 'Somebody',
                                                 last_name: 'Else') }

  before do
    AddUserAsCourseTeacher.call(course: course, user: teacher)
    AddUserAsCourseTeacher.call(course: course, user: other_teacher)
  end

  subject(:names) { described_class[course.id] }

  it { should include('Teacher Jim') }
  it { should include('Teacher Bob') }
  it { should_not include('Somebody Else') }
end
