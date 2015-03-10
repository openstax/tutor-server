require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportPage, :type => :routine, :vcr => VCR_OPTS do

  let!(:book_part) { FactoryGirl.create :content_book_part }

  # Store version differences in this hash
  cnx_page_infos = {
    stable: { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083' },
    latest: { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083@4' }
  }

  cnx_page_infos.each do |name, info|
    context "imports the #{name.to_s} version and" do
      it 'creates a new Page' do
        result = nil
        expect {
          result = Content::ImportPage.call(id: info[:id], book_part: book_part)
        }.to change{ Content::Page.count }.by(1)
        expect(result.errors).to be_empty

        expect(result.outputs[:page]).to be_persisted
        expect(result.outputs[:url]).not_to be_blank
        expect(result.outputs[:content]).not_to be_blank
      end

      it 'converts relative links into absolute links' do
        page = Content::ImportPage.call(id: info[:id], book_part: book_part).outputs[:page]
        doc = Nokogiri::HTML(page.content)

        doc.css("*[src]").each do |tag|
          uri = URI.parse(URI.escape(tag.attributes["src"].value))
          expect(uri.absolute?).to eq true
        end
      end

      it 'finds LO tags in the content' do
        result = nil
        expect {
          result = Content::ImportPage.call(id: info[:id], book_part: book_part)
        }.to change{ Content::Topic.count }.by(2)

        topics = Content::Topic.all.to_a
        expect(topics[-2].name).to eq 'k12phys-ch04-s01-lo01'
        expect(topics[-1].name).to eq 'k12phys-ch04-s01-lo02'

        tagged_topics = result.outputs[:topics]
        expect(tagged_topics).not_to be_empty
        expect(tagged_topics).to eq Content::Page.last.page_topics.collect{|pt| pt.topic}
        expect(tagged_topics.collect{|t| t.name}).to eq [
          'k12phys-ch04-s01-lo01',
          'k12phys-ch04-s01-lo02'
        ]
      end

      it 'gets exercises with LO tags from the content' do
        result = nil
        expect {
          result = Content::ImportPage.call(id: info[:id], book_part: book_part)
        }.to change{ Content::Exercise.count }.by(31)

        exercises = Content::Exercise.all.to_a
      end
    end
  end

end
