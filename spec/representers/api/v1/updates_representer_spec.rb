require 'rails_helper'

RSpec.describe Api::V1::UpdatesRepresenter, type: :representer do
  let(:notifications)  { [] }
  let(:representation) { described_class.new OpenStruct.new(notifications: notifications) }

  it 'updates tutor_assets_hash when it changes' do
    expect(OpenStax::Utilities::Assets).to(
      receive(:tags_for).with(:tutor).and_return('<script src="/a/url" />')
    )
    expect(
      representation.to_hash
    ).to include 'tutor_assets_hash' => 'e226430def0160b8160912ccfe1b410a'

    expect(OpenStax::Utilities::Assets).to(
      receive(:tags_for).with(:tutor).and_return('<script src="/a/new/url" />')
    )
    expect(
      representation.to_hash
    ).to include 'tutor_assets_hash' => 'd09b68b6d423987fd8c0cfc9feb1399d'
  end
end
