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

  context 'authored by OpenStax' do
    it 'defaults the author to OpenStax' do
      exercise = FactoryBot.create(:content_exercise)

      expect(exercise.user_profile_id).to eq User::Models::OpenStaxProfile::ID
    end

    it 'skips generating a number' do
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)
      exercise = FactoryBot.create(:content_exercise, user_profile_id: 0)

      expect(exercise.number).not_to eq(1000001)
    end
  end

  context 'authored by a teacher' do
    let(:profile_one) { FactoryBot.create(:user_profile) }
    let(:profile_two) { FactoryBot.create(:user_profile) }

    it 'generates a number and uuid' do
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)
      exercise = FactoryBot.create(:content_exercise, user_profile_id: profile_one.id, number: nil)

      expect(exercise.number).to eq(1000001)
      expect(exercise.uuid).not_to be_nil
      expect(exercise.version).to eq(1)
    end

    it 'generates a number and resets version if the derivable does not belong to the teacher (other teachers or OpenStax)' do
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000000)
      derivable = FactoryBot.create(:content_exercise, version: 5, user_profile_id: profile_two.id)
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)
      exercise  = FactoryBot.create(
        :content_exercise, user_profile_id: profile_one.id, number: derivable.number, derived_from_id: derivable.id
      )

      expect(exercise.number).to eq(1000001)
      expect(exercise.group_uuid).not_to eq(derivable.group_uuid)
      expect(exercise.version).to eq(1)
    end

    it 'uses derivable number and group_uuid, and bumps version if the derivable belongs to the teacher' do
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)

      derivable = FactoryBot.create(:content_exercise, user_profile_id: profile_one.id)
      derivable.update_attributes(version: 5)
      exercise  = FactoryBot.create(
        :content_exercise, user_profile_id: profile_one.id, derived_from_id: derivable.id
      )

      expect(exercise.number).to eq(derivable.number)
      expect(exercise.group_uuid).to eq(derivable.group_uuid)
      expect(exercise.version).to eq(6)
    end

    context 'setting coauthors' do
      it 'saves normally' do
        allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)
        os_exercise = FactoryBot.create(:content_exercise)
        derivable   = FactoryBot.create(:content_exercise, user_profile_id: profile_one.id, derived_from: os_exercise)
        exercise    = FactoryBot.create(
          :content_exercise, user_profile_id: profile_two.id, number: derivable.number, derived_from: derivable
        )

        expect(exercise.coauthor_profile_ids).to eq([User::Models::OpenStaxProfile::ID, profile_one.id, profile_two.id])
      end

      it 'saves anonymously and avoids adding real id duplicates' do
        allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1000001)
        anon_exercise = FactoryBot.create(:content_exercise, user_profile_id: profile_two.id, anonymize_author: true)
        derivable = FactoryBot.create(:content_exercise, user_profile_id: profile_one.id, derived_from: anon_exercise)
        exercise  = FactoryBot.create(
          :content_exercise, user_profile_id: profile_one.id, number: derivable.number, derived_from: derivable
        )

        expect(exercise.coauthor_profile_ids).to eq([User::Models::AnonymousAuthorProfile::ID, profile_one.id])
      end
    end
  end
end
