# To allow use in the development environment
require_relative '../../vcr_helper'

unless defined?(MINI_ECOSYSTEM_CNX_BOOK_HASH)
  MINI_ECOSYSTEM_CNX_PAGE_HASHES = [
    {
      id: 'b0ffd0a2-9c83-4d73-b899-7f2ade2acda6',
      title: 'Newtons First Law of Motion: Inertia'
    },
    {
      id: '920725c6-229b-4f50-870b-b87366ce4f9e',
      title: 'Newtons Second Law of Motion: Concept of a System'
    },
    {
      id: 'fa572504-16f8-48c3-ab25-1da9f602d097',
      title: 'Newtons Third Law of Motion: Symmetry in Forces'
    },
    {
      id: '533d782d-bcde-44b0-8913-a03b6470dae1',
      title: 'Normal, Tension, and Other Examples of Forces'
    },
    {
      id: 'dcb38c0d-6525-4011-8525-98c16665f266',
      title: 'Problem-Solving Strategies'
    }
  ]
  MINI_ECOSYSTEM_CNX_CHAPTER_HASHES = [
    {
      title: "Dynamics: Force and Newton's Laws of Motion",
      contents: MINI_ECOSYSTEM_CNX_PAGE_HASHES
    }
  ]
  MINI_ECOSYSTEM_CNX_BOOK_HASH = {
    id: '405335a3-7cff-4df2-a9ad-29062a4af261',
    version: '8.32',
    title: 'College Physics with Courseware',
    tree: {
      id: '405335a3-7cff-4df2-a9ad-29062a4af261@8.32',
      title: 'College Physics with Courseware',
      contents: MINI_ECOSYSTEM_CNX_CHAPTER_HASHES
    }
  }
end

FactoryBot.define do
  factory :mini_ecosystem, parent: :content_ecosystem do
    transient do
      reading_processing_instructions do
        FactoryBot.build(:content_book).reading_processing_instructions
      end
    end

    after(:build) do |ecosystem, evaluator|
      ecosystem.save!

      VCR.use_cassette(
        'PopulateMiniEcosystem/with_book',
        # different specs seem to trigger differring behaviour
        VCR_OPTS.merge(allow_unused_http_interactions: true)
      ) do
        Content::ImportBook.call(
          cnx_book: OpenStax::Cnx::V1::Book.new(
            hash: MINI_ECOSYSTEM_CNX_BOOK_HASH.deep_stringify_keys
          ),
          ecosystem: ecosystem,
          reading_processing_instructions: evaluator.reading_processing_instructions
        )
      end
    end
  end
end
