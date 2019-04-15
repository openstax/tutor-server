require 'rails_helper'

RSpec.describe Tasks::Models::TaskedReading, type: :model do
  subject(:tasked_reading) do
    FactoryBot.build(:tasks_tasked_reading, id: 1)
  end

  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:content) }

  describe '#content_preview' do

    before do
      tasked_reading.content = content
    end

    context "When document title is present" do
      let(:content_preview_doc_title) { "Introduction to Science Doc Title" }

      let(:content) do
        <<~HTML
        <body>
          <div data-type="document-title" id="35337">
            <span class="os-text">#{content_preview_doc_title}</span>
          </div>
        </body>
        HTML
      end

      it "parses the content for the content preview" do
        expect(tasked_reading.content_preview).to eq(content_preview_doc_title)
      end
    end

    context "When document title is missing but contains a data-type title" do
      let(:content_preview_title) { "Introduction to Science Title" }

      let(:content) do
        <<~HTML
        <body>
          <div data-type="title" id="35337">
            <span class="os-text">#{content_preview_title}</span>
          </div>
        </body>
        HTML
      end

      it "parses the content for the content preview" do
        expect(tasked_reading.content_preview).to eq(content_preview_title)
      end
    end

    context "When data title is missing but contains a class title" do
      let(:content_preview_class) { "Introduction to Science Class" }

      let(:content) do
        <<~HTML
        <body>
          <div class="os-chapter-outline">
            <h3 class="os-title">#{content_preview_class}</h3>
          </div>
        </body>
        HTML
      end

      it "parses the content for the content preview" do
        expect(tasked_reading.content_preview).to eq(content_preview_class)
      end
    end

    context "When there is no markup with title content" do
      let(:content) do
        <<~HTML
        <body>
        </body>
        HTML
      end

      it "defaults to page title" do
        expect(tasked_reading.content_preview).to eq(tasked_reading.task_step.page.title)
      end
    end
  end
end
