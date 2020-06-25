require 'rails_helper'

RSpec.describe CloneCourse, type: :routine do
  let(:course) { FactoryBot.create :course_profile_course }
  let(:user)   { FactoryBot.create :user_profile }

  let!(:grading_template) { FactoryBot.create :tasks_grading_template, course: course }

  it 'creates a copy of a course' do
    result = described_class.call(
      course: course,
      teacher_user: user,
      copy_question_library: false,
      estimated_student_count: 100
    )
    expect(result.errors).to be_empty

    clone = result.outputs.course
    expect(clone).to be_a CourseProfile::Models::Course
    expect(clone.cloned_from).to eq course
    expect(clone.estimated_student_count).to eq 100
    expect(clone.course_assistants.count).to eq 4
    expect(UserIsCourseTeacher[user: user, course: clone]).to eq true
    expect(clone.past_due_unattempted_ungraded_wrq_are_zero).to(
      eq course.past_due_unattempted_ungraded_wrq_are_zero
    )
  end

  it "copies the course's question library if requested" do
    10.times{ FactoryBot.create :course_content_excluded_exercise, course: course }

    result = described_class.call(course: course, teacher_user: user, copy_question_library: true)
    expect(result.errors).to be_empty

    clone = result.outputs.course
    expect(clone).to be_a CourseProfile::Models::Course
    expect(clone.cloned_from).to eq course
    expect(clone.course_assistants.count).to eq 4
    expect(UserIsCourseTeacher[user: user, course: clone]).to eq true
    expect(clone.excluded_exercises.map(&:exercise_number)).to(
      match_array(course.excluded_exercises.map(&:exercise_number))
    )
  end

  context 'pre-wrm course' do
    before { course.update_attribute :ends_at, DateTime.new(2020, 6, 30) }

    it 'assigns default grading templates to the cloned course' do
      result = described_class.call(
        course: course,
        teacher_user: user,
        copy_question_library: false,
        estimated_student_count: 100
      )
      expect(result.errors).to be_empty

      clone = result.outputs.course
      expected_attributes = Tasks::Models::GradingTemplate::DEFAULT_ATTRIBUTES.dup
      expected_attributes.each do |grading_template_attributes|
        grading_template_attributes.each do |key, value|
          grading_template_attributes[key] = value.to_s if value.is_a?(Symbol)
        end
      end
      expect(
        clone.grading_templates.map do |grading_template|
          grading_template.attributes.symbolize_keys.except(
            :id, :course_profile_course_id, :cloned_from_id, :created_at, :updated_at, :deleted_at
          )
        end
      ).to eq expected_attributes

      clone.grading_templates.each do |grading_template|
        expect(grading_template.cloned_from_id).to be_nil
      end
    end
  end

  context 'wrm course' do
    before { course.update_attribute :ends_at, DateTime.new(2020, 7, 2) }

    it "copies the course's grading templates if not pre-wrm" do
      result = described_class.call(
        course: course,
        teacher_user: user,
        copy_question_library: false,
        estimated_student_count: 100
      )
      expect(result.errors).to be_empty

      clone = result.outputs.course
      expect(
        clone.grading_templates.map do |grading_template|
          grading_template.attributes.symbolize_keys.except(
            :id, :course_profile_course_id, :cloned_from_id, :created_at, :updated_at, :deleted_at
          )
        end
      ).to eq(
        course.grading_templates.without_deleted.map do |grading_template|
          grading_template.attributes.symbolize_keys.except(
            :id, :course_profile_course_id, :cloned_from_id, :created_at, :updated_at, :deleted_at
          )
        end
      )

      original_grading_template_ids = course.grading_templates.without_deleted.map(&:id)
      clone.grading_templates.each do |grading_template|
        expect(grading_template.cloned_from_id).to be_in original_grading_template_ids
      end
    end
  end
end
