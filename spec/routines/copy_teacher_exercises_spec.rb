require 'rails_helper'

RSpec.describe CopyTeacherExercises, type: :routine do
  let(:teacher_user)       { FactoryBot.create :user_profile }
  let!(:existing_exercise) { FactoryBot.create :content_exercise, profile: teacher_user }
  let(:new_page)           { FactoryBot.create :content_page }
  let(:mapping)            { [ [ existing_exercise.page.uuid, new_page.uuid ] ] }

  it 'copies teacher exercises based on a given mapping' do
    expect { described_class.call mapping: mapping }.to(
      change { Content::Models::Exercise.count }.by(1)
    )
    new_exercise = Content::Models::Exercise.order(:created_at).last
    expect(new_exercise.page).to eq new_page
    expect(new_exercise.profile).to eq teacher_user
    expect(new_exercise.uuid).not_to eq existing_exercise.uuid
    expect(new_exercise.group_uuid).not_to eq existing_exercise.group_uuid
    expect(new_exercise.number).not_to eq existing_exercise.number
    expect(new_exercise.version).to eq 1
    expect(new_exercise.context).to eq existing_exercise.context
    expect(JSON.parse(new_exercise.content).except('uuid', 'group_uuid', 'number', 'uid')).to(
      eq JSON.parse(existing_exercise.content).except('uuid', 'group_uuid', 'number', 'uid')
    )
  end
end
