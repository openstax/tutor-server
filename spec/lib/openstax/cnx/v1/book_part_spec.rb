require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::BookPart, type: :external do
  cnx_book_infos = [
    { id: "93e2b09d-261c-4007-a987-0b3062fe154b",
      contents: [
        { id: "subcol",
          contents: [
            { id: "1bb611e9-0ded-48d6-a107-fbb9bd900851@2",
              title: "Introduction" },
            { id: "95e61258-2faf-41d4-af92-f62e1414175a@3",
              title: "Force"},
            { id: "640e3e84-09a5-4033-b2a7-b7fe5ec29dc6@3",
              title: "Newton's First Law of Motion: Inertia"}
          ],
          title: "Forces and Newton's Laws of Motion" }
      ],
      title: 'Physics',
      expected: {
        part_classes: [OpenStax::Cnx::V1::BookPart]
      }
    },
    { id: "subcol",
      contents: [
        { id: "1bb611e9-0ded-48d6-a107-fbb9bd900851@2",
          title: "Introduction" },
        { id: "95e61258-2faf-41d4-af92-f62e1414175a@3",
          title: "Force"},
        { id: "640e3e84-09a5-4033-b2a7-b7fe5ec29dc6@3",
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

  def book_part_for(hash)
    OpenStax::Cnx::V1::BookPart.new(hash: HashWithIndifferentAccess.new(hash).except(:expected))
  end

  it "provides info about the book part for the given hash" do
    cnx_book_infos.each do |hash|
      book_part = book_part_for(hash)
      expect(book_part.hash).not_to be_blank
      expect(book_part.title).to eq hash[:title]
      expect(book_part.contents).not_to be_blank
      expect(book_part.parts).not_to be_empty
    end
  end

  it "can retrieve its children parts" do
    cnx_book_infos.each do |hash|
      book_part = book_part_for(hash)

      expect(book_part.parts.map(&:class)).to(
        eq hash[:expected][:part_classes]
      )
    end
  end
end
