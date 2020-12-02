require 'rails_helper'

RSpec.describe Content::Models::Exercise, type: :model do
  subject{ FactoryBot.create :content_exercise }

  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:number) }
  it { is_expected.to validate_presence_of(:version) }

  it 'splits parts' do
    multipart = FactoryBot.create(:content_exercise, num_questions: 2)
    questions = multipart.questions
    expect(questions.length).to eq 2

    expect(questions.first.id).to be_kind_of(String)

    first = JSON.parse(questions.first.content)
    second = JSON.parse(questions.second.content)

    expect(first['questions']).to be_kind_of(Array)

    expect(first['questions'].first['stem_html']).to match('(0)')
    expect(second['questions'].first['stem_html']).to match('(1)')
  end

  it 'defaults the author to OpenStax' do
    exercise = FactoryBot.create(:content_exercise)

    expect(exercise.user_profile_id).to eq User::Models::OpenStaxProfile::ID
  end

  it 'generates a number if the exercise was created by a teacher' do
    allow_any_instance_of(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)
    exercise = FactoryBot.create(:content_exercise, user_profile_id: 1, number: nil)

    expect(exercise.number).to eq(1000001)
    expect(exercise.version).to eq(1)
  end

  it 'bumps version number if the exercise is derived' do
    allow_any_instance_of(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)

    derivable = FactoryBot.create(:content_exercise, version: 5)
    exercise  = FactoryBot.create(
      :content_exercise, user_profile_id: 1, number: derivable.number, derived_from_id: derivable.id
    )

    expect(exercise.number).to eq(derivable.number)
    expect(exercise.version).to eq(6)
  end

  it 'does not generate a number if the exercise was created by OpenStax' do
    allow_any_instance_of(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)
    exercise = FactoryBot.create(:content_exercise, user_profile_id: 0)

    expect(exercise.number).not_to eq(1000001)
  end
end
