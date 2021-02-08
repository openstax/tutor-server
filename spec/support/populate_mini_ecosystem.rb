require 'vcr_helper'

module PopulateMiniEcosystem
  def self.generate_mini_ecosystem
    cnx_page_hashes = [
      { id: 'b0ffd0a2-9c83-4d73-b899-7f2ade2acda6', title: 'Newtons First Law of Motion: Inertia' },
      { id: '920725c6-229b-4f50-870b-b87366ce4f9e', title: 'Newtons Second Law of Motion: Concept of a System' },
      { id: 'fa572504-16f8-48c3-ab25-1da9f602d097', title: 'Newtons Third Law of Motion: Symmetry in Forces' },
      { id: '533d782d-bcde-44b0-8913-a03b6470dae1', title: 'Normal, Tension, and Other Examples of Forces' },
      { id: 'dcb38c0d-6525-4011-8525-98c16665f266', title: 'Problem-Solving Strategies' },
    ]

    cnx_chapter_hashes = [
      { title: "Dynamics: Force and Newton's Laws of Motion", contents: cnx_page_hashes }
    ]

    cnx_book = OpenStax::Cnx::V1::Book.new hash: {
      id: '405335a3-7cff-4df2-a9ad-29062a4af261',
      version: '8.32',
      title: 'College Physics with Courseware',
      tree: {
        id: '405335a3-7cff-4df2-a9ad-29062a4af261@8.32',
        title: 'College Physics with Courseware',
        contents: cnx_chapter_hashes
      }
    }.deep_stringify_keys

    @ecosystem = FactoryBot.create :content_ecosystem

    reading_processing_instructions = FactoryBot.build(
      :content_book
    ).reading_processing_instructions

    @book = VCR.use_cassette(
      'PopulateMiniEcosystem/with_book',
      # different specs seem to trigger differring behaviour
      VCR_OPTS.merge({ allow_unused_http_interactions: true })
    ) do
      Content::ImportBook.call(
        cnx_book: cnx_book,
        ecosystem: @ecosystem,
        reading_processing_instructions: reading_processing_instructions
      ).outputs.book
    end

    @ecosystem
  end

  def generate_mini_ecosystem
    PopulateMiniEcosystem.generate_mini_ecosystem
  end
end
