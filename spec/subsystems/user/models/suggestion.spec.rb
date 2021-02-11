require 'rails_helper'

RSpec.describe User::Models::Suggestion, type: :model do
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:topic) }

  it 'limits the length of subject suggestions' do
    suggestion = FactoryBot.create(
      :user_suggestion, content: Faker::Lorem.paragraph
    )

    expect(suggestion.content.length).to eq 49
  end
end
