require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::PopulatePlaceholderSteps, type: :routine do

  before(:all) do
    @task_plan = FactoryGirl.create(:tasked_task_plan, number_of_students: 1)
    @course = @task_plan.owner
    @page = Content::Models::Page.where(id: @task_plan.settings['page_ids']).take
    @task = @task_plan.tasks.find do |task|
      task.taskings.any? { |tasking| tasking.role.student.present? }
    end
    @role = @task.taskings.take.role

    (@task.personalized_task_steps + @task.spaced_practice_task_steps).each do |task_step|
      expect(task_step).to be_placeholder
      expect(task_step).not_to be_exercise
    end
  end

  before  do
    @task.reload
    @task.touch
  end

  subject { described_class.call(task: @task) }

  context 'with no dynamic exercises available' do
    before { OpenStax::Biglearn::Api.client.reset! }
    after  { OpenStax::Biglearn::Api.create_update_assignments task: @task, course: @course }

    it 'removes all the placeholder steps from the task' do
      expect { subject }.to  change { @task.personalized_task_steps.size    }.to(0)
                        .and change { @task.spaced_practice_task_steps.size }.to(0)
                        .and change { @task.pes_are_assigned  }.from(false).to(true)
                        .and change { @task.spes_are_assigned }.from(false).to(true)
    end
  end

  context 'with enough dynamic exercises available' do
    context 'with no other tasks' do
      it 'populates all the placeholder steps in the task' do
        expect { subject }.to  not_change { @task.personalized_task_steps.size    }
                          .and not_change { @task.spaced_practice_task_steps.size }

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
