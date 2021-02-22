require 'rails_helper'
require 'vcr_helper'

RSpec.describe GetTeacherGuide, type: :routine, speed: :slow do
  let(:ecosystem) { generate_mini_ecosystem }
  let(:book) { ecosystem.books.first }
  let(:offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }
  let(:course) {
    FactoryBot.create :course_profile_course, :with_grading_templates,
                      offering: offering, is_preview: true
  }
  let(:period) { FactoryBot.create :course_membership_period, course: course }
  let(:second_period) { FactoryBot.create :course_membership_period, course: course }

  let(:teacher) { FactoryBot.create(:user_profile) }
  let(:student) { FactoryBot.create(:user_profile) }
  let(:second_student) { FactoryBot.create(:user_profile) }

  let(:role) { AddUserAsPeriodStudent[period: period, user: student] }
  let(:second_role) { AddUserAsPeriodStudent[period: second_period, user: second_student] }
  let(:teacher_role) { AddUserAsCourseTeacher[course: course, user: teacher] }

  subject(:guide)                { described_class[role: teacher_role].map(&:deep_symbolize_keys) }

  let(:period_1_chapters)        { guide.first[:children] }
  let(:period_1_worked_chapters) do
    period_1_chapters.select { |ch| ch[:questions_answered_count] > 0 }
  end
  let(:period_2_chapters)        { guide.second[:children] }
  let(:period_2_worked_chapters) do
    period_2_chapters.select { |ch| ch[:questions_answered_count] > 0 }
  end

  let(:clue_matcher) do
    a_hash_including(
      minimum: kind_of(Numeric),
      most_likely: kind_of(Numeric),
      maximum: kind_of(Numeric),
      is_real: be_in([true, false])
    )
  end

  context 'without work' do
    context 'without periods' do
      before(:each) do
        period.reload.destroy
        second_period.reload.destroy
      end

      it 'returns an empty array' do
        expect(guide).to eq []
      end
    end

    context 'with periods' do
      it 'returns an empty guide per period' do
        period
        second_period
        expect(guide).to match [
          {
            period_id: period.id,
            title: book.title,
            page_ids: [],
            children: []
          },
          {
            period_id: second_period.id,
            title: book.title,
            page_ids: [],
            children: []
          }
        ]
      end
    end
  end

  context 'with work' do
    before(:each) do
      role
      second_role
      teacher_role
      CreateStudentHistory[course: course.reload, roles: [role.reload, second_role.reload]]
    end

    it 'returns all course guide periods for teachers' do
      expect(guide).to include(
        a_hash_including(
          period_id: period.id,
          title: book.title,
          page_ids: [kind_of(Integer)]*5,
          children: [kind_of(Hash)]
        )
      )
      expect(period_1_worked_chapters).to eq period_1_chapters
      expect(period_2_worked_chapters).to eq period_2_chapters
    end

    it 'includes chapter stats for each period' do
      period_1_chapter_1 = period_1_chapters.first
      expect(period_1_chapter_1).to include(
        title: "Dynamics: Force and Newton's Laws of Motion",
        book_location: [],
        student_count: 1,
        questions_answered_count: 7,
        clue: clue_matcher,
        page_ids: [kind_of(Integer)]*5,
        children: [kind_of(Hash)]*5,
        first_worked_at: kind_of(Time),
        last_worked_at: kind_of(Time)
      )

      period_2_chapter_1 = period_2_chapters.first
      expect(period_2_chapter_1).to include(
        title: "Dynamics: Force and Newton's Laws of Motion",
        book_location: [],
        student_count: 1,
        questions_answered_count: 7,
        clue: clue_matcher,
        page_ids: [kind_of(Integer)]*5,
        first_worked_at: kind_of(Time),
        last_worked_at: kind_of(Time),
        children: [kind_of(Hash)]*5,
      )
    end

    it 'includes page stats for each period and each chapter' do
      period_1_chapter_1_pages = period_1_chapters.first[:children]
      expect(period_1_chapter_1_pages).to include(
        a_hash_including(
          title: 'Newtons First Law of Motion: Inertia',
          book_location: [],
          student_count: 1,
          questions_answered_count: 7,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)],
          first_worked_at: kind_of(Time),
          last_worked_at: kind_of(Time)
        )
      )
    end
  end
end
