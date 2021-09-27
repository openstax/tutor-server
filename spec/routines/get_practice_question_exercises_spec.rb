require 'rails_helper'

RSpec.describe GetPracticeQuestionExercises, type: :routine do
  let(:course)          { FactoryBot.create :course_profile_course }
  let(:period)          { FactoryBot.create :course_membership_period, course: course }

  let(:student_user) { FactoryBot.create(:user_profile) }
  let(:student_role) { AddUserAsPeriodStudent[user: student_user, period: period] }
  let(:book)       { FactoryBot.create(:content_book, :standard_contents_1) }

  let!(:ecosystem) do
    book.ecosystem.reload.tap do |ecosystem|
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
    end
  end

  let(:new_ecosystem) { FactoryBot.create :mini_ecosystem }
  let(:new_book) { FactoryBot.create(:content_book, ecosystem: new_ecosystem) }
  let(:old_book) { ecosystem.books.first }
  let(:old_page) { old_book.pages.first }

  let(:new_page) do
    FactoryBot.create(:content_page, book: new_book, ecosystem: new_ecosystem).tap do |page|
      page.uuid = old_page.uuid
      page.save!
    end
  end

  let(:old_exercise) do
    FactoryBot.create(:content_exercise, page: old_page).tap do |exercise|
      old_page.homework_dynamic_exercise_ids << exercise.id
      old_page.save!
    end
  end
  let(:new_exercise) do
    FactoryBot.create(:content_exercise, page: new_page).tap do |exercise|
      new_page.homework_dynamic_exercise_ids << exercise.id
      new_page.save!
    end
  end

  it 'returns exercises saved in new and old ecosystems' do
    AddEcosystemToCourse[course: course, ecosystem: new_ecosystem]
    old_practice = FactoryBot.create(:tasks_practice_question,
                                     role: student_role,
                                     content_exercise_id: old_exercise.id)
    new_practice = FactoryBot.create(:tasks_practice_question,
                                     role: student_role,
                                     content_exercise_id: new_exercise.id)
    exercise_ids = [old_exercise.id, new_exercise.id]

    outputs = described_class.call(
      role: student_role,
      course: course,
      exercise_ids: exercise_ids
    ).outputs

    expect(outputs.exercises.map(&:id)).to eq(exercise_ids)
  end
end
