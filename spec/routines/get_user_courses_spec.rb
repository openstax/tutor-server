require 'rails_helper'

RSpec.describe GetUserCourses, type: :routine do

  it 'gets courses, not duped' do
    user = FactoryBot.create(:user_profile)

    course = FactoryBot.create :course_profile_course
    period = FactoryBot.create :course_membership_period, course: course

    AddUserAsCourseTeacher[user: user, course: course]
    AddUserAsPeriodStudent[user: user, period: period]

    courses = GetUserCourses[user: user]

    expect(courses).to eq [course]
  end

  it 'gets multiple courses for a user' do
    user = FactoryBot.create(:user_profile)

    course_1 = FactoryBot.create :course_profile_course
    course_1_period = FactoryBot.create :course_membership_period, course: course_1
    course_2 = FactoryBot.create :course_profile_course
    course_3 = FactoryBot.create :course_profile_course
    course_3_period = FactoryBot.create :course_membership_period, course: course_3

    AddUserAsCourseTeacher[user: user, course: course_2]
    AddUserAsPeriodStudent[user: user, period: course_3_period]
    AddUserAsPeriodStudent[user: user, period: course_1_period]

    courses = GetUserCourses[user: user, types: :student]

    expect(courses).to contain_exactly(course_1, course_3)
  end

  it 'does not return courses where the user is an inactive student' do
    user = FactoryBot.create(:user_profile)

    course_1 = FactoryBot.create :course_profile_course
    course_1_period = FactoryBot.create :course_membership_period, course: course_1
    course_2 = FactoryBot.create :course_profile_course
    course_3 = FactoryBot.create :course_profile_course
    course_3_period = FactoryBot.create :course_membership_period, course: course_3

    AddUserAsPeriodStudent[user: user, period: course_1_period]
    AddUserAsCourseTeacher[user: user, course: course_2]
    course_3_role = AddUserAsPeriodStudent[user: user, period: course_3_period]

    course_3_role.student.destroy

    courses = GetUserCourses[user: user, types: :student]

    expect(courses).to eq [course_1]
  end

  it 'does not return courses where the user is a deleted teacher' do
    user = FactoryBot.create(:user_profile)

    course_1 = FactoryBot.create :course_profile_course
    course_1_period = FactoryBot.create :course_membership_period, course: course_1
    course_2 = FactoryBot.create :course_profile_course
    course_3 = FactoryBot.create :course_profile_course
    course_3_period = FactoryBot.create :course_membership_period, course: course_3

    course_2_role = AddUserAsCourseTeacher[user: user, course: course_2]
    AddUserAsPeriodStudent[user: user, period: course_3_period]
    AddUserAsPeriodStudent[user: user, period: course_1_period]

    course_2_role.teacher.destroy

    courses = GetUserCourses[user: user, types: :teacher]

    expect(courses).to eq []
  end

end
