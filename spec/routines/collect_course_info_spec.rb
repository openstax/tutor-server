require 'rails_helper'

describe CollectCourseInfo, type: :routine do
  let!(:user_1)    { Entity::User.create! }
  let!(:user_2)    { Entity::User.create! }

  let!(:role_1)    { FactoryGirl.create :entity_role, user: user_1 }
  let!(:role_2)    { FactoryGirl.create :entity_role, user: user_2 }

  let!(:course_1) { FactoryGirl.create(:course_profile_profile).course }
  let!(:course_2) { FactoryGirl.create(:course_profile_profile).course }

  let!(:student_1) { FactoryGirl.create :course_membership_student, role: role_1, course: course_1 }
  let!(:student_2) { FactoryGirl.create :course_membership_student, role: role_2, course: course_2 }

  context "when a course is given" do
    it "returns information about the course" do
      result = described_class[course: course_1]
      expect(result).to contain_exactly(
        {
          id: course_1.id,
          name: course_1.profile.name,
          school_name: course_1.profile.school_name
        }
      )
    end
  end

  context "when a user is given" do
    it "returns information about the user's active courses" do
      result = described_class[user: user_1]
      expect(result).to contain_exactly(
        {
          id: course_1.id,
          name: course_1.profile.name,
          school_name: course_1.profile.school_name
        }
      )
    end
  end

  context "when neither is given" do
    it "returns information about all courses" do
      result = described_class[]
      expect(result).to contain_exactly(
        {
          id: course_1.id,
          name: course_1.profile.name,
          school_name: course_1.profile.school_name
        },
        {
          id: course_2.id,
          name: course_2.profile.name,
          school_name: course_2.profile.school_name
        }
      )
    end
  end
end
