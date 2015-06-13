require 'rails_helper'

RSpec.describe Period, type: :model do
  subject(:period) { FactoryGirl.create :period }

  let!(:student_1_user) { FactoryGirl.create(:user_profile).entity_user }
  let!(:student_2_user) { FactoryGirl.create(:user_profile).entity_user }
  let!(:teacher_user)   { FactoryGirl.create(:user_profile).entity_user }

  let!(:student_1) { AddUserAsPeriodStudent.call(user: student_1_user,
                                                 period: period).outputs.role }
  let!(:student_2) { AddUserAsPeriodStudent.call(user: student_2_user,
                                                 period: period).outputs.role }
  let!(:teacher)   { AddUserAsCourseTeacher.call(user: teacher_user,
                                                 course: period.course).outputs.role }

  it 'exposes course, name, student_roles and teacher_roles' do
    [:course, :name, :student_roles, :teacher_roles].each do |method_name|
      expect(period).to respond_to(method_name)
    end

    expect(period.course).not_to be_blank
    expect(period.name).not_to be_blank
    expect(Set.new period.student_roles).to eq(Set.new [student_1, student_2])
    expect(period.teacher_roles).to eq [teacher]
  end
end
