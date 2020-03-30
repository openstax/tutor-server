require 'rails_helper'

RSpec.describe Tasks::Models::TaskedInteractive, type: :model do
  subject(:tasked_interactive) do
    FactoryBot.build(:tasks_tasked_interactive)
  end

  it { is_expected.to validate_presence_of(:url) }

  context '#content_preview' do
    let(:default_content_preview) { "External Interactive step ##{tasked_interactive.id}" }

    it "parses the content for the content preview" do
      expect(tasked_interactive.content_preview).to eq(tasked_interactive.title)
    end

    it "provides a default if the content preview is missing" do
      tasked_interactive.title = nil
      tasked_interactive.id = 1
      expect(tasked_interactive.content_preview).to eq(default_content_preview)
    end
  end
end
