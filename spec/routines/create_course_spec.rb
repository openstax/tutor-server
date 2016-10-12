require 'rails_helper'

RSpec.describe CreateCourse, type: :routine do
  let(:starts_at)        { Time.current }
  let(:ends_at)          { Time.current + 1.week }
  let(:is_college)       { true }
  let(:is_concept_coach) { false }

  it "creates a new course" do
    result = described_class.call(
      name: 'Unnamed', starts_at: starts_at, ends_at: ends_at,
      is_college: is_college, is_concept_coach: is_concept_coach
    )
    expect(result.errors).to be_empty

    course = result.outputs.course

    expect(course).to be_a Entity::Course
    expect(course.course_assistants.count).to eq 4
  end

  it 'adds a unique registration code for the teacher' do
    allow(SecureRandom).to receive(:hex) { 'abc123' }

    course = described_class.call(
      name: 'Reg Code Course', starts_at: starts_at, ends_at: ends_at,
      is_college: is_college, is_concept_coach: is_concept_coach
    ).outputs.course

    expect(course.teach_token).to eq('abc123')
  end
end
