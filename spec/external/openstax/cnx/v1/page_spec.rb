require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Page, :type => :external,
                                        :vcr => VCR_OPTS do

  cnx_page_infos = HashWithIndifferentAccess.new(
    stable: [{ id: '1491e74e-ed39-446f-a602-e7ab881af101@1',
               title: 'Introduction',
               expected: {
                los: [],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text]
               }
             },
             { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083@4',
               title: 'Force',
               expected: {
                los: ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02'],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text]
               }
             },
             { id: '61445f78-00e2-45ae-8e2c-461b17d9b4fd@3',
               title: 'Newton\'s First Law of Motion: Inertia',
               expected: {
                los: ['k12phys-ch04-s02-lo01', 'k12phys-ch04-s02-lo02'],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text]
               }
             }],
    latest: [{ id: '1491e74e-ed39-446f-a602-e7ab881af101',
               title: 'Introduction',
               expected: {
                los: [],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text]
               }
             },
             { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083',
               title: 'Force',
               expected: {
                los: ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02'],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text]
               }
             },
             { id: '61445f78-00e2-45ae-8e2c-461b17d9b4fd',
               title: 'Newton\'s First Law of Motion: Inertia',
               expected: {
                los: ['k12phys-ch04-s02-lo01', 'k12phys-ch04-s02-lo02'],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text]
               }
             }]
  )

  cnx_page_infos.each do |name, infos|
    context "with #{name.to_s} content" do
      it "provides info about the content" do
        infos.each do |hash|
          page = OpenStax::Cnx::V1::Page.new(hash: hash.except(:expected))
          expect(page.id).to eq hash[:id]
          expect(page.url).to include(hash[:id])
          expect(page.title).to eq hash[:title]
          expect(page.full_hash).not_to be_empty
          expect(page.content).not_to be_blank
          expect(page.doc).not_to be_nil
          expect(page.converted_content).not_to be_blank
          expect(page.root).not_to be_nil
          expect(page.los).not_to be_nil
          expect(page.fragments).not_to be_nil
        end
      end

      it "converts relative url's to absolute url's" do
        infos.each do |hash|
          page = OpenStax::Cnx::V1::Page.new(hash: hash.except(:expected))
          doc = Nokogiri::HTML(page.converted_content)

          doc.css('[src]').each do |tag|
            uri = URI.parse(URI.escape(tag.attributes['src'].value))
            expect(uri.absolute?).to eq true
          end
        end
      end

      it "extracts the LO's from the page" do
        infos.each do |hash|
          page = OpenStax::Cnx::V1::Page.new(hash: hash.except(:expected))

          expect(page.los).to eq hash[:expected][:los]
        end
      end

      it "splits the page into fragments" do
        infos.each do |hash|
          page = OpenStax::Cnx::V1::Page.new(hash: hash.except(:expected))

          expect(page.fragments.collect{|f| f.class}).to(
            eq hash[:expected][:fragment_classes]
          )
        end
      end
    end
  end

end
