require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'
require 'support/biglearn_real_client_vcr_helper'

module OpenStax::Biglearn
  RSpec.describe V1::RealClient, type: :external, vcr: VCR_OPTS do

    # If you need to regenerate some cassettes and biglearn-dev is giving you errors,
    # first make sure you have valid keys for exchange-dev and it is not stubbed (test env),
    # then disable VCR and run this spec
    # After it is done, enable VCR, stub exchange once more and then regenerate your cassettes

    context 'with users and pools' do
      before(:all) do
        DatabaseCleaner.start

        configuration = OpenStax::Biglearn::V1::Configuration.new
        configuration.server_url = 'https://biglearn-dev.openstax.org/'
        @client = described_class.new(configuration)

        VCR.use_cassette('OpenStax_Biglearn_V1_RealClient/with_users_and_pools', VCR_OPTS) do
          user_1 = User::CreateUser[username: SecureRandom.hex]
          @user_1_role = Role::CreateUserRole[user_1]

          user_2 = User::CreateUser[username: SecureRandom.hex]
          @user_2_role = Role::CreateUserRole[user_2]

          # Biglearn only returns valid CLUe's for positive exercise numbers
          exercise_1_content = OpenStax::Exercises::V1.fake_client.new_exercise_hash(
            number: 42
          ).to_json
          content_exercise_1 = FactoryGirl.create :content_exercise, content: exercise_1_content
          exercise_url_1 = Addressable::URI.parse(content_exercise_1.url)
          exercise_url_1.scheme = nil
          exercise_url_1.path = exercise_url_1.path.split('@').first
          @biglearn_exercise_1 = OpenStax::Biglearn::V1::Exercise.new(
            question_id: exercise_url_1.to_s,
            version: content_exercise_1.version,
            tags: content_exercise_1.exercise_tags.map{ |et| et.tag.value }
          )
          exercise_2_content = OpenStax::Exercises::V1.fake_client.new_exercise_hash(
            number: 43
          ).to_json
          content_exercise_2 = FactoryGirl.create :content_exercise, content: exercise_2_content
          exercise_url_2 = Addressable::URI.parse(content_exercise_2.url)
          exercise_url_2.scheme = nil
          exercise_url_2.path = exercise_url_2.path.split('@').first
          @biglearn_exercise_2 = OpenStax::Biglearn::V1::Exercise.new(
            question_id: exercise_url_2.to_s,
            version: content_exercise_2.version,
            tags: content_exercise_2.exercise_tags.map{ |et| et.tag.value }
          )
          @biglearn_exercise_2_new = OpenStax::Biglearn::V1::Exercise.new(
            question_id: @biglearn_exercise_2.question_id,
            version: @biglearn_exercise_2.version + 1,
            tags: @biglearn_exercise_2.tags
          )
          biglearn_exercises = [@biglearn_exercise_1,
                                @biglearn_exercise_2,
                                @biglearn_exercise_2_new]

          @client.add_exercises(biglearn_exercises)

          @biglearn_pool_1 = OpenStax::Biglearn::V1::Pool.new(exercises: [@biglearn_exercise_1])
          @biglearn_pool_2 = OpenStax::Biglearn::V1::Pool.new(exercises: [@biglearn_exercise_2])
          @biglearn_pool_3 = OpenStax::Biglearn::V1::Pool.new(exercises: [@biglearn_exercise_1,
                                                                          @biglearn_exercise_2_new])
          biglearn_pools = [@biglearn_pool_1, @biglearn_pool_2, @biglearn_pool_3]

          biglearn_pool_uuids = @client.add_pools(biglearn_pools)
          biglearn_pools.each_with_index do |biglearn_pool, index|
            biglearn_pool.uuid = biglearn_pool_uuids[index]
          end

          OpenStax::Exchange.record_grade(user_1.exchange_write_identifier,
                                          content_exercise_1.url, '1', 1, 'tutor')
          OpenStax::Exchange.record_grade(user_1.exchange_write_identifier,
                                          content_exercise_2.url, '2', 0, 'tutor')
          OpenStax::Exchange.record_grade(user_1.exchange_write_identifier,
                                          content_exercise_1.url, '1', 0, 'tutor')
          OpenStax::Exchange.record_grade(user_1.exchange_write_identifier,
                                          content_exercise_2.url, '2', 1, 'tutor')
        end
      end

      after(:all) do
        DatabaseCleaner.clean
      end

      context 'post facts_questions API' do
        it 'calls the API well and returns the result' do
          expect(@client.add_exercises([@biglearn_exercise_1])).to(
            eq [ { 'message' => 'Question tags saved.' } ]
          )
        end

        it 'does not call the API and returns an empty array if an empty array is given' do
          expect(@client.add_exercises([])).to eq []
        end
      end

      context 'post facts_pools API' do
        it 'calls the API well and returns the result' do
          expect(@client.add_pools([@biglearn_pool_1])).to contain_exactly(a_kind_of(String))
        end
      end

      context 'post projections_questions API' do
        it 'calls the API well and returns the result' do
          question_ids = @client.get_projection_exercises(
            role: @user_1_role, pools: [@biglearn_pool_1], pool_exclusions: [],
            count: 5, difficulty: 0.5, allow_repetitions: true
          )

          expect(question_ids.size).to eq 5
          question_ids.each{ |question_id| expect(question_id).to be_a String }

          question_ids = @client.get_projection_exercises(
            role: @user_2_role, pools: [@biglearn_pool_2], pool_exclusions: [],
            count: 5, difficulty: 0.5, allow_repetitions: false
          )

          expect(question_ids.size).to eq 1
          expect(question_ids.first).to eq @biglearn_exercise_2.question_id
        end

        xit 'performs requests with exclusion pools properly' do
          question_ids = @client.get_projection_exercises(
            role: @user_1_role, pools: [@biglearn_pool_3],
            pool_exclusions: [{pool: @biglearn_pool_1, ignore_versions: false}],
            count: 5, difficulty: 0.5, allow_repetitions: false
          )

          expect(question_ids.size).to eq 1
          expect(question_ids.first).to eq @biglearn_exercise_2_new.question_id

          question_ids = @client.get_projection_exercises(
            role: @user_2_role, pools: [@biglearn_pool_3],
            pool_exclusions: [{pool: @biglearn_pool_2, ignore_versions: false}],
            count: 5, difficulty: 0.5, allow_repetitions: false
          )

          expect(question_ids.size).to eq 2
          expect(Set.new question_ids).to(
            eq Set.new [@biglearn_exercise_1, @biglearn_exercise_2_new].map(&:question_id)
          )

          question_ids = @client.get_projection_exercises(
            role: @user_2_role, pools: [@biglearn_pool_3],
            pool_exclusions: [{pool: @biglearn_pool_2, ignore_versions: true}],
            count: 5, difficulty: 0.5, allow_repetitions: false
          )

          expect(question_ids.size).to eq 1
          expect(question_ids.first).to eq @biglearn_exercise_1.question_id
        end
      end

      context 'get knowledge_clue API' do
        # Use an empty cache for the following examples
        before(:each) {
          @original_cache = Rails.cache
          Rails.cache = ActiveSupport::Cache::MemoryStore.new
        }
        # Restore the original cache
        after(:each) { Rails.cache = @original_cache }

        let!(:valid_clues_response) {
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
                  pool_id: @biglearn_pool_1.uuid
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
                  pool_id: @biglearn_pool_2.uuid
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
            sample_size_interpretation: "below",
            unique_learner_count: 0
          }
        }
        let!(:pool_2_clue) {
          {
            value: 0.9,
            value_interpretation: "high",
            confidence_interval: [ 0.8, 1.0 ],
            confidence_interval_interpretation: "good",
            sample_size: 100,
            sample_size_interpretation: "above",
            unique_learner_count: 50
          }
        }

        context 'single role' do
          it 'calls the API well and returns the result' do
            pools = [@biglearn_pool_1, @biglearn_pool_2]
            expected_pool_uuids = pools.map(&:uuid)
            clues = @client.get_clues(roles: [@user_1_role], pools: pools)

            expect(clues.size).to eq 2
            clues.each do |pool_uuid, clue|
              expect(expected_pool_uuids).to include pool_uuid
              expect(clue[:value]).to be_a(Float)
              expect(['high', 'medium', 'low']).to include(clue[:value_interpretation])
              expect(clue[:confidence_interval]).to contain_exactly(kind_of(Float), kind_of(Float))
              expect(['good', 'bad']).to include(clue[:confidence_interval_interpretation])
              expect(clue[:sample_size]).to be_kind_of(Integer)
              expect(['above', 'below']).to include(clue[:sample_size_interpretation])
            end
          end

          it 'caches recent CLUe calls' do
            allow(@client).to receive(:request).and_return(valid_clues_response)

            expect(@client).to receive(:request).twice

            # Miss
            clues = @client.get_clues(roles: [@user_1_role], pools: [@biglearn_pool_1,
                                                                    @biglearn_pool_2])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Miss
            clues = @client.get_clues(roles: [@user_2_role], pools: [@biglearn_pool_1,
                                                                    @biglearn_pool_2])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Hit
            clues = @client.get_clues(roles: [@user_2_role], pools: [@biglearn_pool_2,
                                                                    @biglearn_pool_1])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Hit
            clues = @client.get_clues(roles: [@user_1_role], pools: [@biglearn_pool_1,
                                                                    @biglearn_pool_2])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })
          end
        end

        context 'multiple roles' do
          it 'calls the API well and returns the result' do
            pools = [@biglearn_pool_1, @biglearn_pool_2]
            expected_pool_uuids = pools.map(&:uuid)
            clues = @client.get_clues(roles: [@user_1_role, @user_2_role], pools: pools)

            expect(clues.size).to eq 2
            clues.each do |pool_uuid, clue|
              expect(expected_pool_uuids).to include pool_uuid
              expect(clue[:value]).to be_a(Float)
              expect(['high', 'medium', 'low']).to include(clue[:value_interpretation])
              expect(clue[:confidence_interval]).to contain_exactly(kind_of(Float), kind_of(Float))
              expect(['good', 'bad']).to include(clue[:confidence_interval_interpretation])
              expect(clue[:sample_size]).to be_kind_of(Integer)
              expect(['above', 'below']).to include(clue[:sample_size_interpretation])
            end
          end

          it 'caches recent CLUe calls' do
            allow(@client).to receive(:request).and_return(valid_clues_response)

            expect(@client).to receive(:request).exactly(3).times

            # Miss
            clues = @client.get_clues(roles: [@user_1_role],
                                     pools: [@biglearn_pool_1, @biglearn_pool_2])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Miss
            clues = @client.get_clues(roles: [@user_2_role],
                                     pools: [@biglearn_pool_2, @biglearn_pool_1])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Miss
            clues = @client.get_clues(roles: [@user_1_role, @user_2_role],
                                     pools: [@biglearn_pool_1, @biglearn_pool_2])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Hit
            clues = @client.get_clues(roles: [@user_2_role, @user_1_role],
                                     pools: [@biglearn_pool_2, @biglearn_pool_1])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Hit
            clues = @client.get_clues(roles: [@user_2_role],
                                     pools: [@biglearn_pool_2, @biglearn_pool_1])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })

            # Hit
            clues = @client.get_clues(roles: [@user_1_role],
                                     pools: [@biglearn_pool_1, @biglearn_pool_2])
            expect(clues).to eq({ @biglearn_pool_1.uuid => pool_1_clue,
                                  @biglearn_pool_2.uuid => pool_2_clue })
          end
        end
      end
    end
  end
end
