require 'rails_helper'

RSpec.describe GetEcosystemExercisesFromBiglearn, type: :routine do

  let(:pool_model)      { FactoryGirl.create :content_pool }
  let(:page_model)      { FactoryGirl.create :content_page, all_exercises_pool: pool_model }
  let(:ecosystem_model) { page_model.ecosystem }

  let(:exercise_1)      { FactoryGirl.create :content_exercise, page: page_model }
  let(:exercise_2)      { FactoryGirl.create :content_exercise, page: page_model }
  let(:exercise_3)      { FactoryGirl.create :content_exercise, page: page_model }

  let(:exercises)    { [exercise_1, exercise_2, exercise_3] }

  let(:pool)            do
    pool_model.update_attribute(:content_exercise_ids, exercises.map(&:id))
    Content::Pool.new(strategy: pool_model.wrap)
  end

  let(:pools)           { [pool] }

  let(:ecosystem)       { Content::Ecosystem.new(strategy: ecosystem_model.reload.wrap) }

  let(:role)            { FactoryGirl.create :entity_role }

  let(:count)           { 3 }

  context 'success' do
    it 'gets exercises from Biglearn then translates them to local exercises by number' do
      expect(OpenStax::Biglearn::Api).to(
        receive(:get_projection_exercises).once { exercises.map(&:url) }
      )
      expect(ExceptionNotifier).not_to receive(:notify_exception)

      bl_exercises = described_class[ecosystem: ecosystem, role: role, pools: pools, count: count]
      expect(Set.new(bl_exercises.map(&:id))).to eq Set.new(exercises.map(&:id))
    end

    it 'sends the course\'s biglearn_excluded_pool_uuid to Biglearn if the role is a student' do
      course = FactoryGirl.create :course_profile_course
      course.update_attribute :biglearn_excluded_pool_uuid, SecureRandom.uuid
      period = FactoryGirl.create :course_membership_period, course: course
      user = FactoryGirl.create(:user)
      student_role = AddUserAsPeriodStudent[user: user, period: period]

      expect(OpenStax::Biglearn::Api).to receive(:get_projection_exercises).once do |args|
        excluded_pools = args[:pool_exclusions].map{ |pool_exclusion| pool_exclusion[:pool] }
        expect(excluded_pools).to include(a_kind_of(OpenStax::Biglearn::Api::Pool))
        expect(excluded_pools.map(&:uuid)).to include(course.biglearn_excluded_pool_uuid)
        []
      end
      expect(ExceptionNotifier).not_to receive(:notify_exception)

      described_class[ecosystem: ecosystem, role: student_role, pools: pools, count: count]
    end
  end

  context 'failure' do
    it 'retries the request a few times then gets the exercises locally' do
      expect(OpenStax::Biglearn::Api).to(
        receive(:get_projection_exercises)
          .exactly(GetEcosystemExercisesFromBiglearn::MAX_ATTEMPTS).times do
          raise OAuth2::Error, OpenStruct.new(status: 502)
        end
      )
      expect(ExceptionNotifier).to receive(:notify_exception).once

      bl_exercises = described_class[ecosystem: ecosystem, role: role, pools: pools, count: count]
      expect(Set.new(bl_exercises.map(&:id))).to eq Set.new(exercises.map(&:id))
    end

    it 'logs a warning if Biglearn returns less exercises than requested' do
      expect(OpenStax::Biglearn::Api).to(
        receive(:get_projection_exercises).once { exercises.first(2).map(&:url) }
      )

      expect(ExceptionNotifier).not_to receive(:notify_exception)
      expect(WarningMailer).not_to receive(:log_and_deliver)
      expect(Rails.logger).to receive(:warn)

      bl_exercises = described_class[ecosystem: ecosystem, role: role, pools: pools, count: count]
      expect(Set.new(bl_exercises.map(&:id))).to eq Set.new(exercises.first(2).map(&:id))
    end


  end

end
