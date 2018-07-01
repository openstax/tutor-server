require 'rails_helper'

RSpec.describe Research::AdmitStudentsToStudies do

  it "admits every student into every study" do
    student1 = FactoryBot.create(:course_membership_student)
    student2 = FactoryBot.create(:course_membership_student)
    study1 = FactoryBot.create(:research_study)
    study2 = FactoryBot.create(:research_study)

    expect_any_instance_of(described_class).to receive(:admit!).with(student1, study1)
    expect_any_instance_of(described_class).to receive(:admit!).with(student1, study2)
    expect_any_instance_of(described_class).to receive(:admit!).with(student2, study1)
    expect_any_instance_of(described_class).to receive(:admit!).with(student2, study2)

    described_class.call(students: [student1, student2], studies: [study1, study2])
  end

  it "puts students into cohorts" do
    student = FactoryBot.create(:course_membership_student)
    study = FactoryBot.create(:research_study)

    described_class.call(students: student, studies: study)
    expect(student.cohort_members.count).to eq 1
  end

  it "assigns surveys" do
    student = FactoryBot.create(:course_membership_student)
    study = FactoryBot.create(:research_study)
    Research::AddCourseToStudy[course: student.course, study: study]
    survey_plan = FactoryBot.create :research_survey_plan, :published, study: study

    described_class.call(students: student, studies: study)

    expect(student.surveys.count).to eq 1
  end


end
