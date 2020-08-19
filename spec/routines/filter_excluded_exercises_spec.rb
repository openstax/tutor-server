require 'rails_helper'

RSpec.describe FilterExcludedExercises, type: :routine do
  let(:exercises) { 5.times.map { FactoryBot.create :content_exercise } }

  before { Settings::Exercises.excluded_ids = excluded_ids }

  after(:all) { Settings::Exercises.excluded_ids = '' }

  let(:args) do
    {
      exercises: exercises, course: course,
      additional_excluded_numbers: additional_excluded_numbers
    }
  end

  context 'with admin exclusions' do
    let(:excluded_ids) { [ exercises.first.uid, exercises.second.number ].join(', ') }

    context 'with a course with excluded exercises' do
      let(:course)             { FactoryBot.create :course_profile_course }
      let!(:excluded_exercise) do
        FactoryBot.create :course_content_excluded_exercise,
                           course: course, exercise_number: exercises.third.number
      end

      context 'with additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [ exercises.fourth.number ] }

        it 'returns exercises not excluded by admin, course or additional' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq exercises.last(1)
          expect(outputs.admin_excluded_uids).to match_array exercises.first(2).map(&:uid)
          expect(outputs.course_excluded_uids).to eq [ exercises.third.uid ]
          expect(outputs.role_excluded_uids).to eq []
        end
      end

      context 'without additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [] }

        it 'returns exercises not excluded by admin or course' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq exercises.last(2)
          expect(outputs.admin_excluded_uids).to match_array exercises.first(2).map(&:uid)
          expect(outputs.course_excluded_uids).to eq [ exercises.third.uid ]
          expect(outputs.role_excluded_uids).to eq []
        end
      end
    end

    context 'without a course' do
      let(:course) { nil }

      context 'with additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [ exercises.fourth.number ] }

        it 'returns exercises not excluded by admin or additional' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq [ exercises.third, exercises.fifth ]
          expect(outputs.admin_excluded_uids).to match_array exercises.first(2).map(&:uid)
          expect(outputs.course_excluded_uids).to eq []
          expect(outputs.role_excluded_uids).to eq []
        end
      end

      context 'without additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [] }

        it 'returns exercises not excluded by admin' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq exercises.last(3)
          expect(outputs.admin_excluded_uids).to match_array exercises.first(2).map(&:uid)
          expect(outputs.course_excluded_uids).to eq []
          expect(outputs.role_excluded_uids).to eq []
        end
      end
    end
  end

  context 'without admin exclusions' do
    let(:excluded_ids) { '' }

    context 'with a course with excluded exercises' do
      let(:course)             { FactoryBot.create :course_profile_course }
      let!(:excluded_exercise) do
        FactoryBot.create :course_content_excluded_exercise,
                           course: course, exercise_number: exercises.third.number
      end

      context 'with additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [exercises.fourth.number] }

        it 'returns exercises not excluded by course or additional' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq exercises.first(2) + exercises.last(1)
          expect(outputs.admin_excluded_uids).to eq []
          expect(outputs.course_excluded_uids).to eq [ exercises.third.uid ]
          expect(outputs.role_excluded_uids).to eq []
        end
      end

      context 'without additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [] }

        it 'returns exercises not excluded by course' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq exercises.first(2) + exercises.last(2)
          expect(outputs.admin_excluded_uids).to eq []
          expect(outputs.course_excluded_uids).to eq [ exercises.third.uid ]
          expect(outputs.role_excluded_uids).to eq []
        end
      end
    end

    context 'without a course' do
      let(:course) { nil }

      context 'with additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [exercises.fourth.number] }

        it 'returns exercises not excluded by additional' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq exercises.first(3) + exercises.last(1)
          expect(outputs.admin_excluded_uids).to eq []
          expect(outputs.course_excluded_uids).to eq []
          expect(outputs.role_excluded_uids).to eq []
        end
      end

      context 'without additional_excluded_numbers' do
        let(:additional_excluded_numbers) { [] }

        it 'returns all exercises' do
          outputs = described_class.call(**args).outputs
          expect(outputs.exercises).to eq exercises
          expect(outputs.admin_excluded_uids).to eq []
          expect(outputs.course_excluded_uids).to eq []
          expect(outputs.role_excluded_uids).to eq []
        end
      end
    end
  end
end
