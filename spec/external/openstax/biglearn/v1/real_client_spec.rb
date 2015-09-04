require 'rails_helper'
require 'vcr_helper'

module OpenStax::Biglearn
  RSpec.describe V1::RealClient, type: :external, vcr: VCR_OPTS do

    let(:configuration) {
      c = OpenStax::Biglearn::V1::Configuration.new
      c.server_url = 'http://biglearn-dev.openstax.org/'
      c
    }

    let(:client) { described_class.new(configuration) }

    xit 'calls projection questions API well' do
      profile = UserProfile::CreateProfile.call(username: SecureRandom.hex).outputs.profile
      profile.update_attribute(:exchange_read_identifier, '123')
      role = Role::CreateUserRole[profile.entity_user]

      client.get_projection_exercises(
        role: role , pools: pools, count: 5,
        difficulty: 0.5, allow_repetitions: true
      )
    end

    xit 'calls clues API well' do
      identifiers = ['0edbe5f8f30abc5ba56b5b890bddbbe2']
      roles = identifiers.collect do |identifier|
        profile = UserProfile::CreateProfile.call(username: SecureRandom.hex).outputs.profile
        profile.update_attribute(:exchange_read_identifier, identifier)
        Role::CreateUserRole[profile.entity_user]
      end

      # This assumes that a book has been imported
      clues = client.get_clues(roles: roles, pools: pools)

      clues.each do |clue|
        expect(clue[:value]).to be_a(Float)
        expect(['high', 'medium', 'low']).to include(clue[:value_interpretation])
        expect(clue[:confidence_interval]).to contain_exactly(kind_of(Float), kind_of(Float))
        expect(['good', 'bad']).to include(clue[:confidence_interval_interpretation])
        expect(clue[:sample_size]).to be_kind_of(Integer)
        expect(['above', 'below']).to include(clue[:sample_size_interpretation])
      end
    end

  end
end
