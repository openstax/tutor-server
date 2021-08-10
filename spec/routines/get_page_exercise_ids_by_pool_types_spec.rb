require 'rails_helper'

RSpec.describe GetPageExerciseIdsByPoolTypes, type: :routine do
  let!(:page_1)   { FactoryBot.create :content_page }
  let!(:page_2)   { FactoryBot.create :content_page, book: page_1.book }
  let!(:page_3)   { FactoryBot.create :content_page, book: page_1.book }

  let(:ecosystem) { page_1.book.ecosystem }

  context 'when page_ids are not given' do
    context 'when pool_types are not given' do
      it 'returns a map of pool_types for all pools in the given ecosystem' do
        pools_map = described_class[ecosystem: ecosystem]

        pools = [ page_1, page_2, page_3 ].flat_map do |page|
          page.all_exercise_ids +
          page.practice_widget_exercise_ids +
          page.reading_dynamic_exercise_ids +
          page.reading_context_exercise_ids +
          page.homework_core_exercise_ids +
          page.homework_dynamic_exercise_ids
        end

        expect(Set.new pools_map.keys).to eq Set.new Content::Models::Page::POOL_TYPES.map(&:to_s)
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end

    context 'when pool_types are given' do
      let(:pool_types) { [ 'reading_dynamic', 'homework_core' ] }

      it 'returns a map with the given pool_types for the relevant pools in the given ecosystem' do
        pools_map = described_class[ecosystem: ecosystem, pool_types: pool_types]

        pools = [ page_1, page_2, page_3 ].flat_map do |page|
          page.reading_dynamic_exercise_ids + page.homework_core_exercise_ids
        end

        expect(Set.new pools_map.keys).to eq Set.new pool_types
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end
  end

  context 'when page_ids are given' do
    let(:pages) { [ page_1, page_2 ] }

    context 'when pool_types are not given' do
      it 'returns a map of pool_types for all pools in the given pages' do
        pools_map = described_class[ecosystem: ecosystem, page_ids: pages.map(&:id)]

        pools = pages.flat_map do |page|
          page.all_exercise_ids +
          page.practice_widget_exercise_ids +
          page.reading_dynamic_exercise_ids +
          page.reading_context_exercise_ids +
          page.homework_core_exercise_ids +
          page.homework_dynamic_exercise_ids
        end

        expect(Set.new pools_map.keys).to eq Set.new Content::Models::Page::POOL_TYPES.map(&:to_s)
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end

    context 'when pool_types are given' do
      let(:pool_types) { [ 'reading_dynamic', 'homework_core' ] }

      it 'returns a map with the given pool_types for the relevant pools in the given pages' do
        pools_map = described_class[ecosystem: ecosystem,
                                    page_ids: pages.map(&:id),
                                    pool_types: pool_types]

        pools = pages.flat_map do |page|
          page.reading_dynamic_exercise_ids + page.homework_core_exercise_ids
        end

        expect(Set.new pools_map.keys).to eq Set.new pool_types
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end

    context 'after an ecosystem update' do
      let(:course)            { FactoryBot.create :course_profile_course }
      let!(:updated_page_1)   do
        FactoryBot.create :content_page, ecosystem: course.ecosystem, uuid: page_1.uuid
      end
      let(:teacher)           { FactoryBot.create :course_membership_teacher, course: course }
      let!(:teacher_exercise) do
        FactoryBot.create :content_exercise, page: page_1, profile: teacher.role.profile
      end

      it 'still returns the instructor exercises even after the update' do
        expect(described_class[course: teacher.course, page_ids: [ updated_page_1.id ]]).to eq(
          'all' => [ teacher_exercise.id ],
          'homework_core' => [ teacher_exercise.id ],
          'homework_dynamic' => [ teacher_exercise.id ],
          'practice_widget' => [ teacher_exercise.id ],
          'reading_context' => [],
          'reading_dynamic' => []
        )
      end
    end
  end
end
