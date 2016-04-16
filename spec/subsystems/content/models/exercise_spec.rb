require 'rails_helper'

RSpec.describe Content::Models::Exercise, :type => :model do
  subject{ FactoryGirl.create :content_exercise }

  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:number) }
  it { is_expected.to validate_presence_of(:version) }

  it 'splits parts' do
    multipart = FactoryGirl.create(:content_exercise, num_parts: 2)
    separated = multipart.content_as_independent_parts
    expect(separated.length).to eq 2

    first = JSON.parse(separated[0])
    second = JSON.parse(separated[1])

    expect(first['questions']).to be_kind_of(Array)

    expect(first['questions'][0]['stem_html']).to match("(0)")
    expect(second['questions'][0]['stem_html']).to match("(1)")
  end
end
