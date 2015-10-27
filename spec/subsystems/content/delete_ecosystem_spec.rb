require 'rails_helper'

RSpec.describe Content::DeleteEcosystem, type: :routine do
  let!(:course) { CreateCourse[name: 'A Course'] }
  let!(:ecosystem) { FactoryGirl.create(:content_ecosystem) }

  it 'deletes the ecosystem' do
    output = Content::DeleteEcosystem.call(id: ecosystem.id)
    expect(output.errors).to be_empty
    expect(Content::Models::Ecosystem.exists?(ecosystem.id)).to be false
  end

  it 'raises an error if the ecosystem is linked to a course' do
    ecosystem.courses << course
    output = Content::DeleteEcosystem.call(id: ecosystem.id)
    expect(output.errors.first.code).to eq(:ecosystem_cannot_be_deleted)
    expect(output.errors.first.message).to eq(
      'The ecosystem cannot be deleted because it is linked to a course')
    expect(Content::Models::Ecosystem.exists?(ecosystem.id)).to be true
  end
end
