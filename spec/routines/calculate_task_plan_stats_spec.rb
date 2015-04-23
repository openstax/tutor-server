require 'rails_helper'
require 'vcr_helper'

describe CalculateTaskPlanStats, :type => :routine, :vcr => VCR_OPTS do

  let(:number_of_students) { 8 }

  let(:task_plan) {
    FactoryGirl.create :tasked_task_plan,
                       number_of_students: number_of_students
  }

  let(:stats){
    CalculateTaskPlanStats.call(plan: task_plan).outputs.stats
  }

  context "With an unworked plan" do

    it "is all nil or zero for an unworked task_plan" do
      expect(stats.course.mean_grade_percent).to be_nil
      expect(stats.course.total_count).to eq(task_plan.tasks.length)
      expect(stats.course.complete_count).to eq(0)
      expect(stats.course.partially_complete_count).to eq(0)

      page = stats.course.current_pages[0]
      expect(page.student_count).to eq(8)
      expect(page.incorrect_count).to eq(0)
      expect(page.correct_count).to eq(0)
    end

  end

  context "after task steps are marked as completed" do

    it "records partial/complete status" do

      tasks = task_plan.tasks.to_a
      first_task = tasks.first
      step = first_task.task_steps.where(
        tasked_type: "Tasks::Models::TaskedReading"
      ).first
      MarkTaskStepCompleted.call(task_step: step)

      stats = CalculateTaskPlanStats.call(plan: task_plan).outputs.stats
      expect(stats.course.mean_grade_percent).to be_nil
      expect(stats.course.complete_count).to eq(0)
      expect(stats.course.partially_complete_count).to eq(1)

      first_task.task_steps.each{ |ts| MarkTaskStepCompleted.call(task_step: ts) }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats

      expect(stats.course.mean_grade_percent).to eq (0)
      expect(stats.course.complete_count).to eq(1)
      expect(stats.course.partially_complete_count).to eq(0)

      last_task = tasks.last
      MarkTaskStepCompleted.call(task_step: last_task.task_steps.first)
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.course.mean_grade_percent).to eq (0)
      expect(stats.course.complete_count).to eq(1)
      expect(stats.course.partially_complete_count).to eq(1)
    end


  end

  context "after task steps are marked as correct or incorrect" do

    it "records them" do
      tasks = task_plan.tasks.to_a
      first_task = tasks.first
      first_task.task_steps.each{ |ts|
        if ts.tasked_type.demodulize == "TaskedExercise"
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.course.mean_grade_percent).to eq (100)
      expect(stats.course.complete_count).to eq(1)
      expect(stats.course.partially_complete_count).to eq(0)
      page = stats.course.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(number_of_students)
      expect(page['correct_count']).to eq(1)
      expect(page['incorrect_count']).to eq(0)

      second_task = tasks.second
      second_task.task_steps.each{ |ts|
        if ts.tasked_type.demodulize == "TaskedExercise"
          ts.tasked.free_response = 'a sentence not explaining anything'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.course.mean_grade_percent).to eq (50)
      expect(stats.course.complete_count).to eq(2)
      expect(stats.course.partially_complete_count).to eq(0)
      page = stats.course.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(number_of_students)
      expect(page['correct_count']).to eq(1)
      expect(page['incorrect_count']).to eq(1)

      third_task = tasks.third
      third_task.task_steps.each{ |ts|
        if ts.tasked_type.demodulize == "TaskedExercise"
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.course.mean_grade_percent).to eq (67)
      expect(stats.course.complete_count).to eq(3)
      expect(stats.course.partially_complete_count).to eq(0)
      page = stats.course.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(number_of_students)
      expect(page['correct_count']).to eq(2)
      expect(page['incorrect_count']).to eq(1)

      fourth_task = tasks.fourth
      fourth_task.task_steps.each{ |ts|
        if ts.tasked_type.demodulize == "TaskedExercise"
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.course.mean_grade_percent).to eq (75)
      expect(stats.course.complete_count).to eq(4)
      expect(stats.course.partially_complete_count).to eq(0)
      page = stats.course.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(number_of_students)
      expect(page['correct_count']).to eq(3)
      expect(page['incorrect_count']).to eq(1)
    end

  end

end
