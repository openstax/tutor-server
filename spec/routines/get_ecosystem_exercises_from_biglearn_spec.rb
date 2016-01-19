require 'rails_helper'

describe GetEcosystemExercisesFromBiglearn, type: :routine do

  let!(:pool_model)      { FactoryGirl.create :content_pool }
  let!(:page_model)      { FactoryGirl.create :content_page, all_exercises_pool: pool_model }
  let!(:ecosystem_model) { page_model.ecosystem }

  let!(:exercise_1)      { FactoryGirl.create :content_exercise, page: page_model }
  let!(:exercise_2)      { FactoryGirl.create :content_exercise, page: page_model }
  let!(:exercise_3)      { FactoryGirl.create :content_exercise, page: page_model }

  let!(:exercises)    { [exercise_1, exercise_2, exercise_3] }

  let!(:pool)            do
    pool_model.update_attribute(:content_exercise_ids, exercises.map(&:id))
    Content::Pool.new(strategy: pool_model.wrap)
  end

  let!(:pools)           { [pool] }

  let!(:ecosystem)       { Content::Ecosystem.new(strategy: ecosystem_model.reload.wrap) }

  let!(:role)            { Entity::Role.create! }

  let!(:count)           { 5 }

  context 'success' do
    it 'gets exercises from Biglearn then translates them to local exercises by number' do
      expect(OpenStax::Biglearn::V1).to(
        receive(:get_projection_exercises).once { exercises.map(&:url) }
      )
      expect(ExceptionNotifier).not_to receive(:notify_exception)

      bl_exercises = described_class[ecosystem: ecosystem, role: role, pools: pools, count: count]
      expect(Set.new(bl_exercises.map(&:id))).to eq Set.new(exercises.map(&:id))
    end
  end

  context 'failure' do
    it 'retries a few times then gets the exercises locally' do
      expect(OpenStax::Biglearn::V1).to(
        receive(:get_projection_exercises)
          .exactly(GetEcosystemExercisesFromBiglearn::MAX_ATTEMPTS).times do
          raise OAuth2::Error, OpenStruct.new(status: 502)
        end
      )
      expect(ExceptionNotifier).to receive(:notify_exception).once

      bl_exercises = described_class[ecosystem: ecosystem, role: role, pools: pools, count: count]
      expect(Set.new(bl_exercises.map(&:id))).to eq Set.new(exercises.map(&:id))
    end
  end

end
