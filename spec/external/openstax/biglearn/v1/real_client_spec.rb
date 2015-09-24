require 'rails_helper'
require 'vcr_helper'

module OpenStax::Biglearn
  RSpec.describe V1::RealClient, type: :external, vcr: VCR_OPTS do

    # If you need to regenerate the cassette for this spec, first make sure there is some data
    # in biglearn-dev, then get a couple of identifiers and pool uuids from there
    USER_1_IDENTIFIER = '21332ca231a015a11df464d759dd7de0da971bd48334ebb050540ec683f548fe'
    USER_2_IDENTIFIER = '8e79ebcd72d5061496ad94b471686015dccd126e6a42a3dd122bf15590abe8b7'
    POOL_1_UUID = 'c8183974-c247-41a0-ad38-e69b72159b76'
    POOL_2_UUID = '5e816a18-9fdb-4430-9cb8-de2661940b3b'

    let(:configuration) {
      c = OpenStax::Biglearn::V1::Configuration.new
      c.server_url = 'https://biglearn-dev.openstax.org/'
      c
    }

    let(:client) { described_class.new(configuration) }

    let!(:user_1_role) {
      user = User::CreateUser[username: SecureRandom.hex,
                              exchange_identifiers: Hashie::Mash.new(read: USER_1_IDENTIFIER,
                                                                     write: SecureRandom.hex)]
      Role::CreateUserRole[user]
    }

    let!(:user_2_role) {
      user = User::CreateUser[username: SecureRandom.hex,
                              exchange_identifiers: Hashie::Mash.new(read: USER_2_IDENTIFIER,
                                                                     write: SecureRandom.hex)]
      Role::CreateUserRole[user]
    }

    let!(:content_exercise)  { FactoryGirl.create :content_exercise }
    let!(:biglearn_exercise) {
      exercise_url = Addressable::URI.parse(content_exercise.url)
      exercise_url.scheme = nil
      exercise_url.path = exercise_url.path.split('@').first
      OpenStax::Biglearn::V1::Exercise.new(question_id: exercise_url.to_s,
                                           version: content_exercise.version,
                                           tags: content_exercise.exercise_tags
                                                                 .collect{ |et| et.tag.value })
    }

    let!(:pool_1) { OpenStax::Biglearn::V1::Pool.new(uuid: POOL_1_UUID,
                                                     exercises: [biglearn_exercise]) }
    let!(:pool_2) { OpenStax::Biglearn::V1::Pool.new(uuid: POOL_2_UUID) }

    let!(:pool_uuids) { [POOL_1_UUID, POOL_2_UUID] }

    let!(:valid_response) {
      Hashie::Mash.new(
        status: 200,
        body: {
          aggregates: [
            {
              aggregate: 0.5,
              confidence: {
                left: 0.0,
                right: 1.0,
                sample_size: 0,
                unique_learner_count: 0
              },
              interpretation: {
                confidence: "bad",
                level: "medium",
                threshold: "below"
              },
              pool_id: POOL_1_UUID
            },
            {
              aggregate: 0.9,
              confidence: {
                left: 0.8,
                right: 1.0,
                sample_size: 100,
                unique_learner_count: 50
              },
              interpretation: {
                confidence: "good",
                level: "high",
                threshold: "above"
              },
              pool_id: POOL_2_UUID
            },
          ]
        }.to_json
      )
    }

    let!(:pool_1_clue) {
      {
        value: 0.5,
        value_interpretation: "medium",
        confidence_interval: [ 0.0, 1.0 ],
        confidence_interval_interpretation: "bad",
        sample_size: 0,
        sample_size_interpretation: "below"
      }
    }
    let!(:pool_2_clue) {
      {
        value: 0.9,
        value_interpretation: "high",
        confidence_interval: [ 0.8, 1.0 ],
        confidence_interval_interpretation: "good",
        sample_size: 100,
        sample_size_interpretation: "above"
      }
    }

    context 'questions API' do
      it 'calls the API well and returns the result' do
        question_ids = client.get_projection_exercises(
          role: user_1_role, pools: [pool_1], count: 5, difficulty: 0.5, allow_repetitions: true
        )

        expect(question_ids.size).to eq 5
        question_ids.each{ |question_id| expect(question_id).to be_a String }

        question_ids = client.get_projection_exercises(
          role: user_2_role, pools: [pool_2], count: 5, difficulty: 0.5, allow_repetitions: true
        )

        expect(question_ids.size).to eq 5
        question_ids.each{ |question_id| expect(question_id).to be_a String }
      end
    end

    context 'CLUe API' do
      # Use an empty cache for the following examples
      before(:each) {
        @original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
      }
      # Restore the original cache
      after(:each) { Rails.cache = @original_cache }

      context 'single user' do
        it 'calls the API well and returns the result' do
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1, pool_2])

          expect(clues.size).to eq 2
          clues.each do |pool_uuid, clue|
            expect(pool_uuids).to include pool_uuid
            expect(clue[:value]).to be_a(Float)
            expect(['high', 'medium', 'low']).to include(clue[:value_interpretation])
            expect(clue[:confidence_interval]).to contain_exactly(kind_of(Float), kind_of(Float))
            expect(['good', 'bad']).to include(clue[:confidence_interval_interpretation])
            expect(clue[:sample_size]).to be_kind_of(Integer)
            expect(['above', 'below']).to include(clue[:sample_size_interpretation])
          end
        end

        it 'caches recent CLUe calls' do
          allow(client).to receive(:request).and_return(valid_response)

          expect(client).to receive(:request).twice

          # Miss
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Miss
          clues = client.get_clues(roles: [user_2_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_2_role], pools: [pool_2, pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })
        end

        it 'invalidates cached CLUes when a new question is answered' do
          tasked_exercise = FactoryGirl.create :tasks_tasked_exercise,
                                               :with_tasking,
                                               exercise: content_exercise,
                                               tasked_to: user_1_role

          allow(client).to receive(:request).and_return(valid_response)

          expect(client).to receive(:request).twice

          # Miss
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role], pools: [pool_2])
          expect(clues).to eq({ pool_2.uuid => pool_2_clue })

          # Pretend user_1 answered some exercise in pool_1
          tasked_exercise.task_step.complete.save!

          # Miss
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role], pools: [pool_2])
          expect(clues).to eq({ pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })
        end
      end

      context 'multiple users' do
        it 'calls the API well and returns the result' do
          clues = client.get_clues(roles: [user_1_role, user_2_role], pools: [pool_1, pool_2])

          expect(clues.size).to eq 2
          clues.each do |pool_uuid, clue|
            expect(pool_uuids).to include pool_uuid
            expect(clue[:value]).to be_a(Float)
            expect(['high', 'medium', 'low']).to include(clue[:value_interpretation])
            expect(clue[:confidence_interval]).to contain_exactly(kind_of(Float), kind_of(Float))
            expect(['good', 'bad']).to include(clue[:confidence_interval_interpretation])
            expect(clue[:sample_size]).to be_kind_of(Integer)
            expect(['above', 'below']).to include(clue[:sample_size_interpretation])
          end
        end

        it 'caches recent CLUe calls' do
          allow(client).to receive(:request).and_return(valid_response)

          expect(client).to receive(:request).exactly(3).times

          # Miss
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Miss
          clues = client.get_clues(roles: [user_2_role], pools: [pool_2, pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Miss
          clues = client.get_clues(roles: [user_1_role, user_2_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_2_role, user_1_role], pools: [pool_2, pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_2_role], pools: [pool_2, pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })
        end

        it 'invalidates cached CLUes when a new question is answered' do
          tasked_exercise = FactoryGirl.create :tasks_tasked_exercise,
                                               :with_tasking,
                                               exercise: content_exercise,
                                               tasked_to: user_1_role

          allow(client).to receive(:request).and_return(valid_response)

          expect(client).to receive(:request).twice

          # Miss
          clues = client.get_clues(roles: [user_1_role, user_2_role], pools: [pool_1, pool_2])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role, user_2_role], pools: [pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue })

          # Hit
          clues = client.get_clues(roles: [user_2_role, user_1_role], pools: [pool_2])
          expect(clues).to eq({ pool_2.uuid => pool_2_clue })

          # Pretend user_1 answered some exercise in pool_1
          tasked_exercise.task_step.complete.save!

          # Hit
          clues = client.get_clues(roles: [user_1_role, user_2_role], pools: [pool_2])
          expect(clues).to eq({ pool_2.uuid => pool_2_clue })

          # Miss
          clues = client.get_clues(roles: [user_2_role, user_1_role], pools: [pool_2, pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue, pool_2.uuid => pool_2_clue })

          # Hit
          clues = client.get_clues(roles: [user_1_role, user_2_role], pools: [pool_1])
          expect(clues).to eq({ pool_1.uuid => pool_1_clue })
        end
      end
    end
  end
end
