require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::PopulatePlaceholderSteps, type: :routine do
  before(:all) do
    task_plan = FactoryBot.create(:tasked_task_plan, number_of_students: 1)

    page = Content::Models::Page.find_by(id: task_plan.core_page_ids)

    @spaced_page = FactoryBot.create :content_page, book: page.book
    page.exercises.each do |exercise|
      FactoryBot.create :content_exercise, page: @spaced_page, group_uuid: exercise.group_uuid
    end

    @task = task_plan.tasks.find do |task|
      task.taskings.any? { |tasking| tasking.role.student.present? }
    end
    (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
      expect(task_step).to be_placeholder
      expect(task_step).not_to be_exercise
    end
  end

  before  do
    @spaced_page.reload
    @task.reload
  end

  subject { described_class.call(task: @task) }

  context 'with not all core steps completed' do
    before {
      pes = @task.task_steps.filter do |task_step|
        task_step.placeholder? && task_step.group_type == 'personalized_group'
    end

      expect(@task).not_to be_core_task_steps_completed
    }

    context 'with no dynamic exercises available' do
      before do
        expect_any_instance_of(Tasks::FetchAssignmentPes).to receive(:call).and_return(
          Lev::Routine::Result.new(
            Lev::Outputs.new(
              exercises: [],
              eligible_page_ids: @task.core_page_ids.sort,
              initially_eligible_exercise_uids: [],
              admin_excluded_uids: [],
              course_excluded_uids: [],
              role_excluded_uids: []
            ),
            Lev::Errors.new
          )
        )
      end

      it 'removes only the personalized group placeholder steps from the task' do

        expect_any_instance_of(Tasks::Models::Task).to receive(:update_caches_now)

        expect { subject }.to  change     { @task.personalized_task_steps.size    }.to(0)
                          .and not_change { @task.spaced_practice_task_steps.size }
                          .and change     { @task.pes_are_assigned  }.from(false).to(true)
                          .and not_change { @task.spes_are_assigned }
                          .and change     { @task.spy }

        expect(@task.spy.deep_symbolize_keys).to include(
          pes: {
            eligible_page_ids: @task.core_page_ids.sort,
            initially_eligible_exercise_uids: [],
            admin_excluded_uids: [],
            course_excluded_uids: [],
            role_excluded_uids: []
          }
        )
        expect(@task.spy.deep_symbolize_keys.keys).not_to include(:spes)
      end
    end

    it 'populates only the personalized group placeholder steps in the task' do
      expect_any_instance_of(Tasks::Models::Task).to receive(:update_caches_now)

      expect { subject }.to  not_change { @task.personalized_task_steps.size    }
                        .and not_change { @task.spaced_practice_task_steps.size }
                        .and change     { @task.pes_are_assigned  }.from(false).to(true)
                        .and not_change { @task.spes_are_assigned }
                        .and change     { @task.spy }
      expect(@task.spy.deep_symbolize_keys).to include(
        pes: {
          eligible_page_ids: @task.core_page_ids.sort,
          initially_eligible_exercise_uids: kind_of(Array),
          admin_excluded_uids: [],
          course_excluded_uids: [],
          role_excluded_uids: kind_of(Array)
        }
      )
      expect(@task.spy.deep_symbolize_keys.keys).not_to include(:spes)

      @task.personalized_task_steps.each do |task_step|
        expect(task_step).not_to be_placeholder
        expect(task_step).to be_exercise
      end

      @task.spaced_practice_task_steps.each do |task_step|
        expect(task_step).to be_placeholder
        expect(task_step).not_to be_exercise
      end
    end
  end

  context 'with all core steps completed' do
    before do
      # Ensure we don't suddenly get more incomplete core exercises
      # once the personalized placeholders are populated
      @task.personalized_task_steps.each do |task_step|
        task_step.update_attribute :is_core, false
      end

      # We explicitly avoid using MarkTaskStepCompleted here
      # so the placeholder steps are not immediately populated
      @task.core_task_steps.each do |task_step|
        task_step.make_correct! if task_step.exercise?
        task_step.complete!
      end

      expect(@task.reload).to be_core_task_steps_completed
    end

    context 'with no dynamic exercises available' do
      before do
        expect_any_instance_of(Tasks::FetchAssignmentPes).to receive(:call).and_return(
          Lev::Routine::Result.new(
            Lev::Outputs.new(
              exercises: [],
              eligible_page_ids: @task.core_page_ids.sort,
              initially_eligible_exercise_uids: [],
              admin_excluded_uids: [],
              course_excluded_uids: [],
              role_excluded_uids: []
            ),
            Lev::Errors.new
          )
        )
        expect_any_instance_of(Tasks::FetchAssignmentSpes).to receive(:call).and_return(
          Lev::Routine::Result.new(
            Lev::Outputs.new(
              exercises: [],
              eligible_page_ids: [],
              initially_eligible_exercise_uids: [],
              admin_excluded_uids: [],
              course_excluded_uids: [],
              role_excluded_uids: []
            ),
            Lev::Errors.new
          )
        )
      end

      it 'removes all the placeholder steps from the task' do
        expect_any_instance_of(Tasks::Models::Task).to receive(:update_caches_now)

        expect { subject }.to  change { @task.spaced_practice_task_steps.size }.to(0)
                          .and change { @task.pes_are_assigned  }.from(false).to(true)
                          .and change { @task.spes_are_assigned }.from(false).to(true)
                          .and change { @task.spy }
        expect(@task.spy.deep_symbolize_keys).to include(
          spes: {
            eligible_page_ids: [],
            initially_eligible_exercise_uids: [],
            admin_excluded_uids: [],
            course_excluded_uids: [],
            role_excluded_uids: []
          }
        )
      end
    end

    context 'with some SPE slots filled by PEs' do
      before do
        expect_any_instance_of(
          Tasks::FetchAssignmentSpes
        ).to receive(:call).and_wrap_original do |method, *args|
          method.call(*args).tap do |result|
            result.outputs.exercises[0] = @spaced_page.exercises.sample
          end
        end
      end

      it 'populates all the placeholders in the task and changes the group_type of SPE steps' do
        expect_any_instance_of(Tasks::Models::Task).to receive(:update_caches_now)

        num_spe_steps = @task.spaced_practice_task_steps.size

        expect do
          subject
        end.to  change { @task.spaced_practice_task_steps.size }.to(1)
           .and change { @task.pes_are_assigned  }.from(false).to(true)
           .and change { @task.spes_are_assigned }.from(false).to(true)
           .and change { @task.spy }
        expect(@task.spy.deep_symbolize_keys).to include(
          spes: {
            eligible_page_ids: kind_of(Array),
            initially_eligible_exercise_uids: kind_of(Array),
            admin_excluded_uids: [],
            course_excluded_uids: [],
            role_excluded_uids: kind_of(Array)
          }
        )

        @task.personalized_task_steps.each do |task_step|
          expect(task_step).not_to be_placeholder
          expect(task_step).to be_exercise
        end
      end
    end

    context 'with enough dynamic exercises available' do
      let(:exercises) { @spaced_page.exercises.sample @task.num_unpopulated_spes }

      before do
        expect_any_instance_of(
          Tasks::FetchAssignmentSpes
        ).to receive(:call) do |task:|
          Lev::Routine::Result.new(
            Lev::Outputs.new(
              exercises: exercises,
              eligible_page_ids: [ @spaced_page.id ],
              initially_eligible_exercise_uids: @spaced_page.exercises.map(&:uid).sort,
              admin_excluded_uids: [],
              course_excluded_uids: [],
              role_excluded_uids: []
            ),
            Lev::Errors.new
          )
        end
      end

      it 'populates all the placeholder steps in the task' do
        expect_any_instance_of(Tasks::Models::Task).to receive(:update_caches_now)

        expect { subject }.to  not_change { @task.reload.personalized_task_steps.size    }
                          .and change     { @task.pes_are_assigned  }.from(false).to(true)
                          .and change     { @task.spes_are_assigned }.from(false).to(true)
                          .and change     { @task.spy }
        expect(@task.spy.deep_symbolize_keys).to include(
          spes: {
            eligible_page_ids: [ @spaced_page.id ],
            initially_eligible_exercise_uids: @spaced_page.exercises.map(&:uid).sort,
            admin_excluded_uids: [],
            course_excluded_uids: [],
            role_excluded_uids: []
          }
        )
        (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
          expect(task_step).not_to be_placeholder
          expect(task_step).to be_exercise
        end
      end
    end
  end
end
