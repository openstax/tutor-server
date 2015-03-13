require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::BookPart, :type => :external do

  cnx_book_infos = HashWithIndifferentAccess.new(
    stable: [
      { id: "7db9aa72-f815-4c3b-9cb6-d50cf5318b58@2.2",
        contents: [
          { id: "subcol",
            contents: [
              { id: "1491e74e-ed39-446f-a602-e7ab881af101@1",
                title: "Introduction" },
              { id: "092bbf0d-0729-42ce-87a6-fd96fd87a083@4",
                title: "Force"},
              { id: "61445f78-00e2-45ae-8e2c-461b17d9b4fd@3",
                title: "Newton's First Law of Motion: Inertia"}
            ],
            title: "Forces and Newton's Laws of Motion" }
        ],
        title: 'Updated Tutor HS Physics Content - legacy',
        expected: {
          part_classes: [OpenStax::Cnx::V1::BookPart]
        }
      },
      { id: "subcol",
        contents: [
          { id: "1491e74e-ed39-446f-a602-e7ab881af101@1",
            title: "Introduction" },
          { id: "092bbf0d-0729-42ce-87a6-fd96fd87a083@4",
            title: "Force"},
          { id: "61445f78-00e2-45ae-8e2c-461b17d9b4fd@3",
            title: "Newton's First Law of Motion: Inertia"}
        ],
        title: "Forces and Newton's Laws of Motion",
        expected: {
          part_classes: [OpenStax::Cnx::V1::Page,
                         OpenStax::Cnx::V1::Page,
                         OpenStax::Cnx::V1::Page]
        }
      }
    ],
    latest: [
      { id: "7db9aa72-f815-4c3b-9cb6-d50cf5318b58",
        contents: [
          { id: "subcol",
            contents: [
              { id: "1491e74e-ed39-446f-a602-e7ab881af101@1",
                title: "Introduction" },
              { id: "092bbf0d-0729-42ce-87a6-fd96fd87a083@4",
                title: "Force"},
              { id: "61445f78-00e2-45ae-8e2c-461b17d9b4fd@3",
                title: "Newton's First Law of Motion: Inertia"}
            ],
            title: "Forces and Newton's Laws of Motion" }
        ],
        title: 'Updated Tutor HS Physics Content - legacy',
        expected: {
          part_classes: [OpenStax::Cnx::V1::BookPart]
        }
      },
      { id: "subcol",
        contents: [
          { id: "1491e74e-ed39-446f-a602-e7ab881af101@1",
            title: "Introduction" },
          { id: "092bbf0d-0729-42ce-87a6-fd96fd87a083@4",
            title: "Force"},
          { id: "61445f78-00e2-45ae-8e2c-461b17d9b4fd@3",
            title: "Newton's First Law of Motion: Inertia"}
        ],
        title: "Forces and Newton's Laws of Motion",
        expected: {
          part_classes: [OpenStax::Cnx::V1::Page,
                         OpenStax::Cnx::V1::Page,
                         OpenStax::Cnx::V1::Page]
        }
      }
    ]
  )

  cnx_book_infos.each do |name, infos|
    context "with #{name.to_s} content" do
      it "provides info about the book part for the given hash" do
        infos.each do |hash|
          book_part = OpenStax::Cnx::V1::BookPart.new(
            hash: hash.except(:expected)
          )
          expect(book_part.hash).not_to be_blank
          expect(book_part.path).to be_blank
          expect(book_part.title).to eq hash[:title]
          expect(book_part.contents).not_to be_blank
          expect(book_part.parts).not_to be_empty
        end
      end

      it "can retrieve its children parts" do
        infos.each do |hash|
          book_part = OpenStax::Cnx::V1::BookPart.new(
            hash: hash.except(:expected)
          )

          expect(book_part.parts.collect{|p| p.class}).to(
            eq hash[:expected][:part_classes]
          )
        end
      end
    end
  end

end
