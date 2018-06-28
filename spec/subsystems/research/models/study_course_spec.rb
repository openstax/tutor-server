require 'rails_helper'

RSpec.describe Research::Models::StudyCourse, type: :model do

  let(:study) { FactoryBot.create :research_study }
  let(:course) { FactoryBot.create :course_profile_course }

  it "cannot be deleted if study ever active" do
    Research::AddCourseToStudy[course: course, study: study]
    Research::ActivateStudy[study]
    study_course = study.study_courses.first
    expect(study_course.destroy).to eq false
    expect(study_course.errors[:base]).to include(/that has been active/)
  end

end
