require 'rails_helper'

RSpec.describe Tasks::Models::TaskedReading, type: :model do
  subject(:tasked_reading) do
    FactoryBot.build(:tasks_tasked_reading, id: 1)
  end

  it { is_expected.to validate_presence_of(:url) }

  context '#content_preview' do
    before do
      tasked_reading.task_step.update_attribute(
        :page, FactoryBot.create(:content_page, content: content)
      )
    end

    context "When document title is present" do
      let(:content_preview_doc_title) { "<i>Introduction to Science Doc Title</i>" }

      let(:content) do
        <<~HTML
          <div data-type="document-title" id="35337">
            #{content_preview_doc_title}
          </div>
          Some other content so the fragment is not discarded as empty
        HTML
      end

      it "parses the content for the content preview" do
        expect(tasked_reading.content_preview).to eq(content_preview_doc_title)
      end
    end

    context "When document title is missing but contains a data-type title" do
      let(:content_preview_title) { "<b>Introduction</b> to Science Title" }

      let(:content) do
        <<~HTML
          <div data-type="title" id="35337">
            #{content_preview_title}
          </div>
        HTML
      end

      it "parses the content for the content preview" do
        expect(tasked_reading.content_preview).to eq(content_preview_title)
      end
    end

    context "When data title is missing but contains a class title" do
      let(:content_preview_class) { "Introduction to <strong>Science</strong> Class" }

      let(:content) do
        <<~HTML
          <div class="os-title">
            #{content_preview_class}
          </div>
        HTML
      end

      it "parses the content for the content preview" do
        expect(tasked_reading.content_preview).to eq(content_preview_class)
      end
    end

    context "When there is no markup with title content" do
      let(:content) { 'Some Content' }

      it "defaults to page title" do
        expect(tasked_reading.content_preview).to eq(tasked_reading.task_step.page.title)
      end
    end
  end
end
