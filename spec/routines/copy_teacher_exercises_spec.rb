require 'rails_helper'

RSpec.describe CopyTeacherExercises, type: :routine do
  let(:teacher_user)       { FactoryBot.create :user_profile }
  let(:existing_page)      { FactoryBot.create :content_page }
  let(:existing_tags)      do
    5.times.map { FactoryBot.create :content_tag, ecosystem: existing_page.ecosystem }
  end
  let(:existing_exercises) do
    2.times.map { FactoryBot.create :content_exercise, profile: teacher_user, page: existing_page }
  end
  let!(:existing_exercise_tags) do
    existing_exercises.flat_map do |exercise|
      existing_tags.sample(3).map do |tag|
        FactoryBot.create :content_exercise_tag, exercise: exercise, tag: tag
      end
    end
  end
  let(:new_page)          { FactoryBot.create :content_page }
  let(:mapping)           { [ [ existing_page.uuid, new_page.uuid ] ] }

  it 'copies teacher exercises based on a given mapping' do
    expect { described_class.call mapping: mapping }.to(
      change { Content::Models::Exercise.count }.by(2)
    )
    existing_uuids = existing_exercises.map(&:uuid)
    existing_group_uuids = existing_exercises.map(&:group_uuid)
    existing_numbers = existing_exercises.map(&:number)
    existing_context = existing_exercises.map(&:context)
    existing_content = existing_exercises.map do |exercise|
      JSON.parse(exercise.content).except('uuid', 'group_uuid', 'number', 'uid')
    end
    existing_tags = existing_exercises.map do |exercise|
      exercise.tags.sort_by(&:value).map do |tag|
        tag.attributes.except('id', 'content_ecosystem_id', 'created_at', 'updated_at')
      end
    end
    Content::Models::Exercise.order(:created_at).last(2).each do |exercise|
      expect(exercise.page).to eq new_page
      expect(exercise.profile).to eq teacher_user
      expect(existing_uuids).not_to include exercise.uuid
      expect(existing_group_uuids).not_to include exercise.group_uuid
      expect(existing_numbers).not_to include exercise.number
      expect(exercise.version).to eq 1
      expect(existing_context).to include exercise.context
      expect(existing_content).to include(
        JSON.parse(exercise.content).except('uuid', 'group_uuid', 'number', 'uid')
      )
      expect(existing_tags).to include(
        exercise.tags.sort_by(&:value).map do |tag|
          tag.attributes.except('id', 'content_ecosystem_id', 'created_at', 'updated_at')
        end
      )
    end
  end
end
