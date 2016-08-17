require 'rails_helper'

RSpec.feature Admin::StatsController do
  background do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)
  end

  context 'visiting the course stats page' do
    let(:school)         { SchoolDistrict::CreateSchool[name: 'Statistical School'] }
    let(:course)         { CreateCourse[name: 'Statistical Course', school: school] }
    let(:periods)        do
      3.times.map { FactoryGirl.create :course_membership_period, course: course }
    end

    let(:teacher_user)   { FactoryGirl.create :user }
    let!(:teacher_role)  { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let!(:student_roles) do
      5.times.map do
        user = FactoryGirl.create :user
        AddUserAsPeriodStudent[period: periods.sample, user: user]
      end
    end

    scenario 'displays course statistics' do
      visit courses_admin_stats_path

      expect(page).to have_content('Course Stats')
      expect(page).to have_content(course.id)
      expect(page).to have_content(course.name)
      expect(page).to have_content(school.name)
      expect(page).to have_content(periods.size)
      expect(page).to have_content(teacher_user.name)
      expect(page).to have_content(student_roles.size)
    end
  end

  context 'visiting the excluded exercise stats page' do
    let(:course)              { CreateCourse[name: 'Exclusive Course'] }

    let(:teacher_user)        { FactoryGirl.create :user }
    let!(:teacher_role)       { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let!(:excluded_exercises) do
      5.times.map { FactoryGirl.create :course_content_excluded_exercise, course: course }
    end

    scenario 'displays excluded exercise statistics' do
      visit excluded_exercises_admin_stats_path

      expect(page).to have_content('Excluded Exercise Stats')

      expect(page).to have_content('By Course:')
      expect(page).to have_content(course.id)
      expect(page).to have_content(course.name)
      expect(page).to have_content(teacher_user.name)
      expect(page).to have_content(excluded_exercises.size)
      expect(page).to have_content(excluded_exercises.map(&:exercise_number).sort.join(', '))

      expect(page).to have_content('By Exercise:')
      excluded_exercises.map(&:exercise_number).each do |number|
        expect(page).to have_content(number)
      end
      expect(page).to have_content(1)
    end
  end

  context 'visiting the concept coach stats page' do
    let!(:tasks)    { 3.times.map { FactoryGirl.create :tasks_task, task_type: :concept_coach } }
    let!(:cc_tasks) { tasks.map{ |task| FactoryGirl.create :tasks_concept_coach_task, task: task } }

    scenario 'displays concept coach statistics' do
      visit concept_coach_admin_stats_path

      expect(page).to have_content('Concept Coach Stats')
      cc_tasks.each do |cc_task|
        expect(page).to have_content(cc_task.page.title)
        expect(page).to have_content(cc_task.task.task_steps.size)
      end

      expect(page).to have_content(cc_tasks.size)
      expect(page).to have_content(0)
    end
  end
end
