require 'rails_helper'
require 'vcr_helper'

module OpenStax::BigLearn
  RSpec.describe V1::RealClient, :type => :external, :vcr => VCR_OPTS do

    let(:configuration) {
      c = OpenStax::BigLearn::V1::Configuration.new
      c.server_url = 'http://api1.biglearn.openstax.org/'
      c
    }

    let(:client) { described_class.new }

    it 'stringifies tag searches' do
      tag_search = {
        _and: [
          {
            _or: [
              'practice-concepts',
              'practice-problem',
              'test-prep-multiple-choice'
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
        '(("practice-concepts" OR "practice-problem" OR "test-prep-multiple-choice") AND ("k12phys-ch04-s01-lo01" OR "k12phys-ch04-s01-lo02"))'
      )
    end

    it 'calls projection questions well' do
      tag_search = {
        _and: [
          {
            _or: [
              'practice-concepts',
              'practice-problem',
              'test-prep-multiple-choice'
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

      profile = UserProfile::CreateProfile.call(attrs: {username: SecureRandom.hex})
                                          .outputs.profile
      profile.update_attribute(:exchange_read_identifier, '123')
      role = Role::CreateUserRole[profile.entity_user]

      client.get_projection_exercises(
        role: role , tag_search: tag_search, count: 5,
        difficulty: 0.5, allow_repetitions: true
      )
    end

  end
end
