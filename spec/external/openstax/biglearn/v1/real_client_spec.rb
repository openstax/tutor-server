require 'rails_helper'
require 'vcr_helper'

module OpenStax::Biglearn
  RSpec.describe V1::RealClient, :type => :external, :vcr => VCR_OPTS do

    let(:configuration) {
      c = OpenStax::Biglearn::V1::Configuration.new
      c.server_url = 'http://biglearn-dev.openstax.org/'
      c
    }

    let(:client) { described_class.new(configuration) }

    it 'stringifies tag searches' do
      tag_search = {
        _and: [
          {
            _or: [
              'os-practice-concepts',
              'os-practice-problems',
              _and: [
                'test-prep',
                'multiple-choice'
              ]
            ]
          },
          {
            _or: [
              'k12phys-ch04-s01-lo01',
              'k12phys-ch04-s01-lo02'
            ]
          }
        ]
      }

      expect(client.stringify_tag_search(tag_search)).to eq(
        '(("os-practice-concepts" OR "os-practice-problems" OR ("test-prep" AND "multiple-choice")) AND ("k12phys-ch04-s01-lo01" OR "k12phys-ch04-s01-lo02"))'
      )
    end

    it 'calls projection questions well' do
      tag_search = {
        _and: [
          {
            _or: [
              'os-practice-concepts',
              'os-practice-problems',
              _and: [
                'test-prep',
                'multiple-choice'
              ]
            ]
          },
          {
            _or: [
              'k12phys-ch04-s01-lo01',
              'k12phys-ch04-s01-lo02'
            ]
          }
        ]
      }

      profile = UserProfile::CreateProfile.call(username: SecureRandom.hex).outputs.profile
      profile.update_attribute(:exchange_read_identifier, '123')
      role = Role::CreateUserRole[profile.entity_user]

      client.get_projection_exercises(
        role: role , tag_search: tag_search, count: 5,
        difficulty: 0.5, allow_repetitions: true
      )
    end

    it 'calls clue well' do
      profile = UserProfile::CreateProfile.call(username: SecureRandom.hex).outputs.profile
      profile.update_attribute(:exchange_read_identifier, '0edbe5f8f30abc5ba56b5b890bddbbe2')
      role = Role::CreateUserRole[profile.entity_user]

      # This assumes that a book has been imported
      clue = client.get_clue(roles: role, tags: 'k12phys-ch04-s02-lo01')

        expect(clue[:aggregate]).to be_a(Float)
        expect(['high', 'medium', 'low']).to include(clue[:level])
        expect(['good', 'bad']).to include(clue[:confidence])
        expect(['above', 'below']).to include(clue[:threshold])
    end

  end
end
