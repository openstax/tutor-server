require 'rails_helper'

RSpec.feature 'admin stats' do
  background do
    admin = FactoryBot.create(:user, :administrator)
    stub_current_user(admin)
  end

  context 'visiting the course stats page' do
    let(:school)         { SchoolDistrict::CreateSchool[name: 'Statistical School'] }
    let(:course)         { FactoryBot.create :course_profile_course, name: 'Statistical Course',
                                                              school: school }
    let(:periods)        do
      3.times.map { FactoryBot.create :course_membership_period, course: course }
    end

    let(:teacher_user)   { FactoryBot.create :user }
    let!(:teacher_role)  { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let!(:student_roles) do
      5.times.map do
        user = FactoryBot.create :user
        AddUserAsPeriodStudent[period: periods.sample, user: user]
      end
    end

    scenario 'displays course statistics' do
      visit admin_stats_courses_path

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
    let(:course)              { FactoryBot.create :course_profile_course }

    let(:teacher_user)        { FactoryBot.create :user }
    let!(:teacher_role)       { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let(:chapter)             { FactoryBot.create :content_chapter }

    let(:pages)               do
      5.times.map do |ii|
        FactoryBot.create :content_page, chapter: chapter, book_location: [1, ii + 1]
      end
    end

    let(:exercises)           do
      pages.each_with_index.map do |page, ii|
        FactoryBot.create :content_exercise, page: page, number: ii - 5
      end.sort_by(&:number)
    end

    let!(:excluded_exercises) do
      exercises.map do |exercise|
        FactoryBot.create :course_content_excluded_exercise, course: course,
                                                              exercise_number: exercise.number
      end
    end

    let(:book)                { chapter.book }
    let(:ecosystem)           { Content::Ecosystem.new(strategy: book.ecosystem.wrap) }

    background { AddEcosystemToCourse[ecosystem: ecosystem, course: course] }

    scenario 'displays excluded exercise statistics' do
      visit admin_stats_excluded_exercises_path

      expect(page).to have_content('Excluded Exercise Stats')

      expect(page).to have_content('By Course:')
      expect(page).to have_content(course.id)
      expect(page).to have_content(course.name)
      expect(page).to have_content(teacher_user.name)
      expect(page).to have_content(exercises.size)
      expect(page).to have_content(exercises.map(&:number).join(', '))
      expect(page).to have_content(excluded_exercises.map(&:created_at).join(', '))
      expect(page).to have_content(book.title)
      expect(page).to have_content(book.uuid)
      expect(page).to have_content(pages.map{ |page| page.book_location.join('.') }.join(', '))
      expect(page).to have_content(pages.map(&:uuid).join(', '))

      expect(page).to have_content('By Exercise:')
      exercises.each do |exercise|
        expect(page).to have_content(exercise.number)
        expect(page).to have_content(exercise.page.uuid)
      end
      expect(page).to have_content(1)
    end
  end
end
