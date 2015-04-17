require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportPage, :type => :routine, :vcr => VCR_OPTS do

  let!(:book_part) { FactoryGirl.create :content_book_part }

  cnx_page_infos = {
    stable: { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083@4', title: 'Force' },
    latest: { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083', title: 'Force' }
  }

  cnx_pages = HashWithIndifferentAccess[cnx_page_infos.collect do |name, info|
    [name, OpenStax::Cnx::V1::Page.new(info)]
  end ]

  cnx_pages.each do |name, cnx_page|
    context "imports the #{name.to_s} version and" do
      it 'creates a new Page' do
        result = nil
        expect {
          result = Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                            book_part: book_part)
        }.to change{ Content::Models::Page.count }.by(1)
        expect(result.errors).to be_empty

        expect(result.outputs[:page]).to be_persisted
      end

      it 'converts relative links into absolute links' do
        page = Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                        book_part: book_part).outputs[:page]
        doc = Nokogiri::HTML(page.content)

        doc.css('[src]').each do |tag|
          uri = URI.parse(URI.escape(tag.attributes['src'].value))
          expect(uri.absolute?).to eq true
        end
      end

      it 'finds LO tags in the content' do
        result = nil
        expect {
          result = Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                            book_part: book_part)
        }.to change{ Content::Models::Tag.lo.count }.by(2)

        tags = Content::Models::Tag.lo.order(:id).to_a
        expect(tags[-2].value).to eq 'k12phys-ch04-s01-lo01'
        expect(tags[-1].value).to eq 'k12phys-ch04-s01-lo02'

        tagged_tags = result.outputs[:tags]
        expect(tagged_tags).not_to be_empty
        expect(tagged_tags).to(
          eq Content::Models::Page.last.page_tags.collect{|pt| pt.tag}
        )
        expect(tagged_tags.collect{|t| t.value}).to eq [
          'k12phys-ch04-s01-lo01',
          'k12phys-ch04-s01-lo02'
        ]
      end

      it 'gets exercises with LO tags from the content' do
        result = nil
        expect {
          result = Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                            book_part: book_part)
        }.to change{ Content::Models::Exercise.count }.by(31)

        exercises = Content::Models::Exercise.all.order(:id).to_a
      end
    end
  end

end
