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

  describe('number generation') do
    let(:exercise) {
      FactoryBot.build(:content_exercise, user_profile_id: user_profile_id)
    }

    describe('created by a teacher') do
      let(:user_profile_id) { 1 }

      it 'has large number' do
        expect(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return 10000
        exercise.number = nil # override whatever factory set
        expect(exercise.authored_by_teacher?).to be(true)
        expect(exercise.save).to be true
        expect(exercise.number).to be 10000
      end
    end

    describe 'when created by OpenStax' do
      let(:user_profile_id) { nil }
      it 'has small number' do
        expect(Content::Models::Exercise).not_to receive(:generate_next_teacher_exercise_number)
        expect(exercise.number).to be < 100
      end
    end
  end
end
