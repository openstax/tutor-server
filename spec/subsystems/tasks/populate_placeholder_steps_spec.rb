require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::PopulatePlaceholderSteps, type: :routine do

  before(:all) do
    task_plan = FactoryGirl.create(:tasked_task_plan, number_of_students: 1)
    @course = task_plan.owner
    page = Content::Models::Page.find_by(id: task_plan.settings['page_ids'])
    @spaced_page = FactoryGirl.create :content_page, chapter: page.chapter
    page.exercises.each do |exercise|
      FactoryGirl.create :content_exercise, page: @spaced_page, group_uuid: exercise.group_uuid
    end
    @task = task_plan.tasks.find do |task|
      task.taskings.any? { |tasking| tasking.role.student.present? }
    end
    @role = @task.taskings.take.role

    (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
      expect(task_step).to be_placeholder
      expect(task_step).not_to be_exercise
    end
  end

  before  { @task.reload.touch }

  subject { described_class.call(task: @task) }

  context 'with no dynamic exercises available' do
    before do
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_pes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            assignment_uuid: request[:task].uuid,
            exercise_uuids: [],
            assignment_status: 'assignment_ready',
            spy_info: {}
          }
        end
      end
      expect(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_spes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            assignment_uuid: request[:task].uuid,
            exercise_uuids: [],
            assignment_status: 'assignment_ready',
            spy_info: {}
          }
        end
      end
    end

    it 'removes all the placeholder steps from the task' do
      expect { subject }.to  change { @task.personalized_task_steps.size    }.to(0)
                        .and change { @task.spaced_practice_task_steps.size }.to(0)
                        .and change { @task.pes_are_assigned  }.from(false).to(true)
                        .and change { @task.spes_are_assigned }.from(false).to(true)
    end
  end

  context 'with some SPE slots filled by PEs' do
    before do
      expect(OpenStax::Biglearn::Api.client).to(
        receive(:fetch_assignment_spes).and_wrap_original do |method, *args|
          method.call(*args).map do |response|
            exercise_uuids = [ @spaced_page.exercises.sample.uuid ] +
                             response[:exercise_uuids][0..-2]

            response.merge(exercise_uuids: exercise_uuids)
          end
        end
      )
    end

    it 'populates all the placeholder steps in the task and changes the group_type of SPE steps' do
      num_spe_steps = @task.spaced_practice_task_steps.size

      expect { subject }.to  change { @task.personalized_task_steps.size    }.by(num_spe_steps - 1)
                        .and change { @task.spaced_practice_task_steps.size }.to(1)
                        .and change { @task.pes_are_assigned  }.from(false).to(true)
                        .and change { @task.spes_are_assigned }.from(false).to(true)

      @task.personalized_task_steps.each do |task_step|
        expect(task_step).not_to be_placeholder
        expect(task_step).to be_exercise
      end
    end
  end

  context 'with enough dynamic exercises available' do
    before do
      allow(OpenStax::Biglearn::Api.client).to receive(:fetch_assignment_spes) do |requests|
        requests.map do |request|
          {
            request_uuid: request[:request_uuid],
            assignment_uuid: request[:task].uuid,
            exercise_uuids: @spaced_page.exercises.map(&:uuid).sample(request[:max_num_exercises]),
            assignment_status: 'assignment_ready',
            spy_info: {}
          }
        end
      end
    end

    context 'with no other tasks' do
      it 'populates all the placeholder steps in the task' do
        expect { subject }.to  not_change { @task.personalized_task_steps.size    }
                          .and not_change { @task.spaced_practice_task_steps.size }
                          .and change { @task.pes_are_assigned  }.from(false).to(true)
                          .and change { @task.spes_are_assigned }.from(false).to(true)

        (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
          expect(task_step).not_to be_placeholder
          expect(task_step).to be_exercise
        end
      end
    end

    context 'with another task of a different type' do
      before do
        other_task_types = Tasks::Models::Task.task_types.keys - [@task.task_type]
        FactoryGirl.create :tasks_task,
                           task_type: other_task_types.sample,
                           tasked_to: @role,
                           due_at: @task.due_at - 1.second
      end

      it 'populates all the placeholder steps in the task' do
        expect { subject }.to  not_change { @task.reload.personalized_task_steps.size    }
                          .and not_change { @task.spaced_practice_task_steps.size }
                          .and change     { @task.pes_are_assigned  }.from(false).to(true)
                          .and change     { @task.spes_are_assigned }.from(false).to(true)

        (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
          expect(task_step).not_to be_placeholder
          expect(task_step).to be_exercise
        end
      end
    end

    context 'with another open task of the same type with a later due date' do
      before do
        FactoryGirl.create :tasks_task,
                           task_type: @task.task_type,
                           tasked_to: @role,
                           due_at: @task.due_at + 1.second
      end

      it 'populates all the placeholder steps in the task' do
        expect { subject }.to  not_change { @task.personalized_task_steps.size    }
                          .and not_change { @task.spaced_practice_task_steps.size }
                          .and change     { @task.pes_are_assigned  }.from(false).to(true)
                          .and change     { @task.spes_are_assigned }.from(false).to(true)

        (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
          expect(task_step).not_to be_placeholder
          expect(task_step).to be_exercise
        end
      end
    end

    context 'with another open task of the same type with an earlier due date' do
      before do
        FactoryGirl.create :tasks_task,
                           task_type: @task.task_type,
                           tasked_to: @role,
                           due_at: @task.due_at - 1.second
      end

      context 'with not all core steps completed' do
        before { expect(@task).not_to be_core_task_steps_completed }

        it 'populates only the personalized group placeholder steps in the task' do
          expect { subject }.to  not_change { @task.personalized_task_steps.size    }
                            .and not_change { @task.spaced_practice_task_steps.size }
                            .and change     { @task.pes_are_assigned  }.from(false).to(true)
                            .and not_change { @task.spes_are_assigned }

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
          # We explicitly avoid using MarkTaskStepCompleted here
          # so the placeholder steps are not immediately populated
          @task.core_task_steps.each do |task_step|
            task_step.make_correct! if task_step.exercise?
            task_step.complete!
          end

          expect(@task.reload).to be_core_task_steps_completed
        end

        it 'populates all the placeholder steps in the task' do
          expect { subject }.to  not_change { @task.personalized_task_steps.size    }
                            .and not_change { @task.spaced_practice_task_steps.size }
                            .and change     { @task.pes_are_assigned  }.from(false).to(true)
                            .and change     { @task.spes_are_assigned }.from(false).to(true)

          (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
            expect(task_step).not_to be_placeholder
            expect(task_step).to be_exercise
          end
        end
      end
    end
  end

end
