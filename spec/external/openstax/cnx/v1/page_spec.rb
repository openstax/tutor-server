require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Page, :type => :external, :vcr => VCR_OPTS do

  cnx_page_infos = HashWithIndifferentAccess.new(
    stable: [{ id: '1491e74e-ed39-446f-a602-e7ab881af101@1',
               title: 'Introduction',
               expected: {
                los: [],
                tags: [],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text],
                is_intro: true
               }
             },
             { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083@4',
               title: 'Force',
               expected: {
                los: ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02'],
                tags: [
                  { value: 'k12phys-ch04-s01-lo01', type: :lo },
                  { value: 'k12phys-ch04-s01-lo02', type: :lo }
                ],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text],
                is_intro: false
               }
             },
             { id: '61445f78-00e2-45ae-8e2c-461b17d9b4fd@3',
               title: 'Newton\'s First Law of Motion: Inertia',
               expected: {
                los: ['k12phys-ch04-s02-lo01', 'k12phys-ch04-s02-lo02'],
                tags: [
                  {
                    value: 'k12phys-ch04-s02-lo01',
                    type: :lo,
                    name: 'Describe Newton\'s first law and friction MATHMATH',
                    teks: 'ost-tag-teks-112-39-c-4d'
                  },
                  {
                    value: 'k12phys-ch04-s02-lo02',
                    type: :lo,
                    name: 'Discuss the relationship between mass and inertia',
                    teks: 'ost-tag-teks-112-39-c-4d'
                  }
                ],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Video,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Interactive,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text],
                is_intro: false
               }
             }],
    latest: [{ id: '1491e74e-ed39-446f-a602-e7ab881af101',
               title: 'Introduction',
               expected: {
                los: [],
                tags: [],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text],
                is_intro: true
               }
             },
             { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083',
               title: 'Force',
               expected: {
                los: ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02'],
                tags: [
                  {
                    value: 'k12phys-ch04-s01-lo01',
                    type: :lo,
                    name: 'Differentiate between force, net force and dynamics',
                    teks: 'ost-tag-teks-112-39-c-4c'
                  },
                  {
                    value: 'k12phys-ch04-s01-lo02',
                    type: :lo,
                    name: 'Draw a free-body diagram',
                    teks: 'ost-tag-teks-112-39-c-4e'
                  },
                  {
                    value: 'ost-tag-teks-112-39-c-4c',
                    type: :teks,
                    name: '4C',
                    description: 'analyze and describe accelerated motion in two dimensions using equations, including projectile and circular examples'
                  }
                ],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Video,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text],
                is_intro: false
               }
             },
             { id: '61445f78-00e2-45ae-8e2c-461b17d9b4fd',
               title: 'Newton\'s First Law of Motion: Inertia',
               expected: {
                los: ['k12phys-ch04-s02-lo01', 'k12phys-ch04-s02-lo02'],
                tags: [
                  {
                    value: 'k12phys-ch04-s02-lo01',
                    type: :lo,
                    name: 'Describe Newton\'s first law and friction a∝1ma∝1m',
                    teks: 'ost-tag-teks-112-39-c-4d'
                  },
                  {
                    value: 'k12phys-ch04-s02-lo02',
                    type: :lo,
                    name: 'Discuss the relationship between mass and inertia',
                    teks: 'ost-tag-teks-112-39-c-4d'
                  },
                  {
                    value: 'ost-tag-teks-112-39-c-4d',
                    type: :teks,
                    name: '(D)',
                    description: 'calculate the effect of forces on objects, including the law of inertia, the relationship between force and acceleration, and the nature of force pairs between objects'
                  }
                ],
                fragment_classes: [OpenStax::Cnx::V1::Fragment::Text,
                                   OpenStax::Cnx::V1::Fragment::Video,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Interactive,
                                   OpenStax::Cnx::V1::Fragment::Exercise,
                                   OpenStax::Cnx::V1::Fragment::Text],
                is_intro: false
               }
             }]
  )

  cnx_page_infos.each do |name, infos|
    context "with #{name.to_s} content" do
      it "provides info about the page for the given hash" do
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
          expect(page.tags).not_to be_nil
        end
      end

      it "converts relative url's to absolute url's" do
        infos.each do |hash|
          page = OpenStax::Cnx::V1::Page.new(hash: hash.except(:expected))
          doc = Nokogiri::HTML(page.converted_content)

          doc.css('[src]').each do |tag|
            uri = URI.parse(URI.escape(tag.attributes['src'].value))
            expect(uri.scheme).to eq('https') if (uri.host == 'archive.cnx.org')
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

      it "can identify chapter introduction pages" do
        infos.each do |hash|
          page = OpenStax::Cnx::V1::Page.new(hash: hash.except(:expected))

          expect(page.is_intro?).to eq hash[:expected][:is_intro]
        end
      end

      it 'extracts tag names and descriptions from the page' do
        infos.each do |hash|
          page = OpenStax::Cnx::V1::Page.new(hash: hash.except(:expected))
          tags = page.tags.collect { |tag| tag.stringify_keys }

          expect(tags).to eq hash[:expected][:tags]
        end
      end
    end
  end

end
