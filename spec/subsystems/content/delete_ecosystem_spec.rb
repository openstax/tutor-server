require 'rails_helper'

RSpec.describe Content::DeleteEcosystem, type: :routine do
  let(:course)      { FactoryBot.create :course_profile_course }
  let(:ecosystem_1) {
    Content::Models::Ecosystem.find(FactoryBot.create(:content_ecosystem).id)
  }
  let(:ecosystem_2) {
    Content::Models::Ecosystem.find(FactoryBot.create(:content_ecosystem).id)
  }

  it 'deletes the ecosystem' do
    output = nil
    expect do
      output = Content::DeleteEcosystem.call(id: ecosystem_1.id)
    end.to change { ecosystem_1.reload.deleted? }.from(false).to(true)
    expect(output.errors).to be_empty
  end

  it 'raises an error if the ecosystem is currently linked to a course' do
    AddEcosystemToCourse[course: course, ecosystem: ecosystem_1]
    output = Content::DeleteEcosystem.call(id: ecosystem_1.id)
    expect(output.errors.first.code).to eq(:ecosystem_cannot_be_deleted)
    expect(output.errors.first.message).to eq(
      'The ecosystem cannot be deleted because it is linked to a course')
    expect(ecosystem_1.reload.deleted?).to eq false
  end

  it 'raises an error if the ecosystem was linked to a course in the past' do
    AddEcosystemToCourse[course: course, ecosystem: ecosystem_1]
    AddEcosystemToCourse[course: course, ecosystem: ecosystem_2]

    # The current ecosystem for the course is ecosystem_2
    expect(GetCourseEcosystem[course: course]).to eq(ecosystem_2)

    # but ecosystem_1 should not be deletable
    output = Content::DeleteEcosystem.call(id: ecosystem_1.id)
    expect(output.errors.first.code).to eq(:ecosystem_cannot_be_deleted)
    expect(output.errors.first.message).to eq(
      'The ecosystem cannot be deleted because it is linked to a course')
    expect(ecosystem_1.reload.deleted?).to eq false
  end
end
