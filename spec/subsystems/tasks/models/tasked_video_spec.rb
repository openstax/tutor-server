require 'rails_helper'

RSpec.describe Tasks::Models::TaskedReading, type: :model do
  it { is_expected.to validate_presence_of(:url) }

  describe '#content_preview' do
    subject(:tasked_video) do
      FactoryBot.build(:tasks_tasked_video)
    end

    let(:default_content_preview) { "External Reading step ##{tasked_video.id}" }

    it "parses the content for the content preview" do
      expect(tasked_video.content_preview).to eq(tasked_video.title)
    end

    it "provides a default if the content preview is missing" do
      tasked_video.title = nil
      tasked_video.id = 1
      expect(tasked_video.content_preview).to eq(default_content_preview)
    end
  end
end
