require 'rails_helper'

RSpec.describe Tasks::Models::TaskedExternalUrl, type: :model do
  it { is_expected.to validate_presence_of(:url) }

  describe '#content_preview' do
    subject(:tasked_exercise) do
      FactoryBot.build(:tasks_tasked_external_url)
    end

    let(:default_content_preview) { "External Url step ##{tasked_exercise.id}" }

    it "parses the content for the content preview" do
      expect(tasked_exercise.content_preview).to eq(tasked_exercise.title)
    end

    it "provides a default if the content preview is missing" do
      tasked_exercise.title = nil
      expect(tasked_exercise.content_preview).to eq(default_content_preview)
    end
  end
end
