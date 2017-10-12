require 'rails_helper'

module CourseMembership
  describe Period, type: :wrapper do
    subject(:period)     { FactoryGirl.create :course_membership_period }

    let(:student_1_user) { FactoryGirl.create(:user) }
    let(:student_2_user) { FactoryGirl.create(:user) }
    let(:teacher_user)   { FactoryGirl.create(:user) }

    let!(:student_1)      { AddUserAsPeriodStudent.call(user: student_1_user,
                                                        period: period).outputs.role }
    let!(:student_2)      { AddUserAsPeriodStudent.call(user: student_2_user,
                                                        period: period).outputs.role }
    let!(:teacher)        { AddUserAsCourseTeacher.call(user: teacher_user,
                                                        course: period.course).outputs.role }

    it 'exposes course, name, student_roles, teacher_roles,
        enrollment_code, archived? and to_model' do
      [:course, :name, :student_roles, :teacher_roles,
       :enrollment_code, :archived?, :to_model].each do |method_name|
        expect(period).to respond_to(method_name)
      end

      expect(period.id).to be_a Integer
      expect(period.course).to be_a CourseProfile::Models::Course
      expect(period.name).to be_a String
      expect(Set.new period.student_roles).to eq(Set.new [student_1, student_2])
      expect(period.teacher_roles).to eq [teacher]
      expect(period.enrollment_code).to be_a String
      expect(period.to_model).to be_a CourseMembership::Models::Period
    end
  end
end
