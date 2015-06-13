require 'rails_helper'
require 'vcr_helper'

describe CalculateTaskPlanStats, type: :routine, speed: :slow, vcr: VCR_OPTS do

  let!(:number_of_students) { 8 }

  let!(:task_plan) {
    allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [ [0, 2] ] }
    allow(Tasks::Assistants::IReadingAssistant).to receive(:num_personalized_exercises) { 0 }
    FactoryGirl.create :tasked_task_plan, number_of_students: number_of_students
  }

  context "With an unworked plan" do

    it "is all nil or zero for an unworked task_plan" do
      stats = CalculateTaskPlanStats.call(plan: task_plan).outputs.stats
      expect(stats.periods.first.mean_grade_percent).to be_nil
      expect(stats.periods.first.total_count).to eq(task_plan.tasks.length)
      expect(stats.periods.first.complete_count).to eq(0)
      expect(stats.periods.first.partially_complete_count).to eq(0)

      page = stats.periods.first.current_pages[0]
      expect(page.student_count).to eq(0) # no students have worked yet
      expect(page.incorrect_count).to eq(0)
      expect(page.correct_count).to eq(0)

      spaced_page = stats.periods.first.spaced_pages[0]
      expect(spaced_page).to eq page
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
      expect(stats.periods.first.mean_grade_percent).to be_nil
      expect(stats.periods.first.complete_count).to eq(0)
      expect(stats.periods.first.partially_complete_count).to eq(1)

      first_task.task_steps.each do |ts|
        MarkTaskStepCompleted.call(task_step: ts) unless ts.completed?
      end
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats

      expect(stats.periods.first.mean_grade_percent).to eq (0)
      expect(stats.periods.first.complete_count).to eq(1)
      expect(stats.periods.first.partially_complete_count).to eq(0)

      last_task = tasks.last
      MarkTaskStepCompleted.call(task_step: last_task.task_steps.first)
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.periods.first.mean_grade_percent).to eq (0)
      expect(stats.periods.first.complete_count).to eq(1)
      expect(stats.periods.first.partially_complete_count).to eq(1)
    end


  end

  context "after task steps are marked as correct or incorrect" do

    it "records them" do
      tasks = task_plan.tasks.to_a
      first_task = tasks.first
      first_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.periods.first.mean_grade_percent).to eq (100)
      expect(stats.periods.first.complete_count).to eq(1)
      expect(stats.periods.first.partially_complete_count).to eq(0)

      page = stats.periods.first.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(1) # num students with completed task steps
      expect(page['correct_count']).to eq(1)
      expect(page['incorrect_count']).to eq(0)
      expect(page['chapter_section']).to eq([1, 1])

      spaced_page = stats.periods.first.spaced_pages.first
      expect(spaced_page['title']).to eq('Force')
      expect(spaced_page['student_count']).to eq(1)
      expect(spaced_page['correct_count']).to eq(2)
      expect(spaced_page['incorrect_count']).to eq(0)
      expect(spaced_page['chapter_section']).to eq([1, 1])

      second_task = tasks.second
      second_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.free_response = 'a sentence not explaining anything'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.periods.first.mean_grade_percent).to eq (50)
      expect(stats.periods.first.complete_count).to eq(2)
      expect(stats.periods.first.partially_complete_count).to eq(0)

      page = stats.periods.first.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(2)
      expect(page['correct_count']).to eq(1)
      expect(page['incorrect_count']).to eq(1)
      expect(page['chapter_section']).to eq([1, 1])

      spaced_page = stats.periods.first.spaced_pages.first
      expect(spaced_page['title']).to eq('Force')
      expect(spaced_page['student_count']).to eq(2)
      expect(spaced_page['correct_count']).to eq(2)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])

      third_task = tasks.third
      third_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.periods.first.mean_grade_percent).to eq (67)
      expect(stats.periods.first.complete_count).to eq(3)
      expect(stats.periods.first.partially_complete_count).to eq(0)

      page = stats.periods.first.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(3)
      expect(page['correct_count']).to eq(2)
      expect(page['incorrect_count']).to eq(1)
      expect(page['chapter_section']).to eq([1, 1])

      spaced_page = stats.periods.first.spaced_pages.first
      expect(spaced_page['title']).to eq('Force')
      expect(spaced_page['student_count']).to eq(3)
      expect(spaced_page['correct_count']).to eq(4)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])

      fourth_task = tasks.fourth
      fourth_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload).outputs.stats
      expect(stats.periods.first.mean_grade_percent).to eq (75)
      expect(stats.periods.first.complete_count).to eq(4)
      expect(stats.periods.first.partially_complete_count).to eq(0)

      page = stats.periods.first.current_pages.first
      expect(page['title']).to eq('Force')
      expect(page['student_count']).to eq(4)
      expect(page['correct_count']).to eq(3)
      expect(page['incorrect_count']).to eq(1)
      expect(page['chapter_section']).to eq([1, 1])

      spaced_page = stats.periods.first.spaced_pages.first
      expect(spaced_page['title']).to eq('Force')
      expect(spaced_page['student_count']).to eq(4)
      expect(spaced_page['correct_count']).to eq(6)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])
    end

    it "returns detailed stats if :details is true" do
      tasks = task_plan.tasks.to_a
      first_task = tasks.first
      first_tasked_exercise = first_task.task_steps.select{ |ts| ts.tasked.exercise? }.first.tasked

      first_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload, details: true).outputs.stats
      exercises = stats.periods.first.current_pages.first.exercises
      exercises.each do |exercise|
        expect(exercise.answered_count).to eq 1
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 1

      second_task = tasks.second
      second_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.free_response = 'a sentence not explaining anything'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload, details: true).outputs.stats
      exercises = stats.periods.first.current_pages.first.exercises
      exercises.each do |exercise|
        expect(exercise.answered_count).to eq 2
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 1

      third_task = tasks.third
      third_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload, details: true).outputs.stats
      exercises = stats.periods.first.current_pages.first.exercises
      exercises.each do |exercise|
        expect(exercise.answered_count).to eq 3
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 2

      fourth_task = tasks.fourth
      fourth_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: task_plan.reload, details: true).outputs.stats
      exercises = stats.periods.first.current_pages.first.exercises
      exercises.each do |exercise|
        expect(exercise.answered_count).to eq 4
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 3
    end

  end

  context "With multiple course periods" do
    let!(:course)   { Entity::Course.create! }
    let!(:period_1) { CreatePeriod[course: course, name: 'Alpha'] }
    let!(:period_2) { CreatePeriod[course: course, name: 'Beta'] }

    before(:each) do
      task_plan.tasking_plans.each_with_index do |tp, ii|
        CourseMembership::AddStudent[period: (ii < task_plan.tasks.length/2 ? period_1 : period_2),
                                     role: tp.target]
      end
    end

    it "splits the students into their periods" do
      stats = CalculateTaskPlanStats.call(plan: task_plan).outputs.stats

      expect(stats.periods.first.mean_grade_percent).to be_nil
      expect(stats.periods.first.total_count).to eq(task_plan.tasks.length/2)
      expect(stats.periods.first.complete_count).to eq(0)
      expect(stats.periods.first.partially_complete_count).to eq(0)

      page = stats.periods.first.current_pages[0]
      expect(page.student_count).to eq(0)
      expect(page.incorrect_count).to eq(0)
      expect(page.correct_count).to eq(0)

      spaced_page = stats.periods.first.spaced_pages[0]
      expect(spaced_page).to eq page

      expect(stats.periods.second.mean_grade_percent).to be_nil
      expect(stats.periods.second.total_count).to eq(task_plan.tasks.length/2)
      expect(stats.periods.second.complete_count).to eq(0)
      expect(stats.periods.second.partially_complete_count).to eq(0)

      page = stats.periods.second.current_pages[0]
      expect(page.student_count).to eq(0)
      expect(page.incorrect_count).to eq(0)
      expect(page.correct_count).to eq(0)

      spaced_page = stats.periods.second.spaced_pages[0]
      expect(spaced_page).to eq page
    end

  end

end
