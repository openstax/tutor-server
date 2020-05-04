require 'rails_helper'

RSpec.describe CourseProfile::ClaimPreviewCourse, type: :routine do
  let(:offering)     { FactoryBot.create :catalog_offering }
  let(:term)         { :preview }
  let(:current_time) { Time.current }
  let(:year)         { current_time.year }
  let(:is_college)   { [true, false, nil].sample }

  before do
    # Not used because no ecosystem
    CreateCourse[
      name: 'Unclaimed',
      term: term,
      year: year,
      timezone: 'US/East-Indiana',
      is_preview: true,
      is_college: true,
      is_test: false,
      catalog_offering: offering,
      estimated_student_count: 42
    ].tap do |course|
      course.course_ecosystems.delete_all :delete_all
      course.update_attribute :is_preview_ready, true
    end
  end

  context 'with preview available' do
    around(:all) { |example| Timecop.freeze(current_time - 3.months) { example.run } }

    let(:course) do
      CreateCourse[
        name: 'Unclaimed',
        term: term,
        year: year,
        timezone: 'US/East-Indiana',
        is_preview: true,
        is_college: true,
        is_test: false,
        catalog_offering: offering,
        estimated_student_count: 42
      ].tap do |course|
        course.course_ecosystems.delete_all :delete_all
        course.update_attribute :is_preview_ready, true
      end
    end
    let!(:task_plan) { FactoryBot.create :tasked_task_plan, course: course }

    before { offering.update_attribute :ecosystem, task_plan.ecosystem }

    it 'finds the course, task plans and tasks and updates their attributes' do
      claimed_course = Timecop.freeze(current_time) do
        described_class[
          catalog_offering: offering, name: 'My New Preview Course', is_college: is_college
        ]
      end
      expect(claimed_course.id).to eq course.id
      expect(claimed_course.name).to eq 'My New Preview Course'
      expect(claimed_course.preview_claimed_at).to eq current_time
      expect(claimed_course.starts_at).to eq current_time.monday - 2.weeks
      expect(claimed_course.ends_at).to eq current_time + 8.weeks - 1.second
      expect(claimed_course.is_college).to eq is_college

      task_plan.reload.tasking_plans.each do |tasking_plan|
        # In case Daylight Savings Time ended less than 3 months ago
        expect(tasking_plan.opens_at).to be_within(1.hour + 1.second).of(current_time)
        # In case Daylight Savings Time starts next week
        expect(tasking_plan.due_at).to be_within(1.hour + 1.second).of(current_time + 1.week)
      end

      task_plan.tasks.each do |task|
        # In case Daylight Savings Time ended less than 3 months ago
        expect(task.opens_at).to be_within(1.hour + 1.second).of(current_time)
        # In case Daylight Savings Time starts next week
        expect(task.due_at).to be_within(1.hour + 1.second).of(current_time + 1.week)
        expect(task.feedback_at).to be_nil
        expect(task.last_worked_at).to be_nil
      end
    end

    context 'with some preview courses with old content' do
      let!(:old_ecosystem_course) do
        CreateCourse[
          name: 'Unclaimed',
          term: term,
          year: year,
          timezone: 'US/East-Indiana',
          is_preview: true,
          is_college: true,
          is_test: false,
          catalog_offering: offering,
          estimated_student_count: 42
        ].tap do |course|
          course.update_attribute :is_preview_ready, true
          FactoryBot.create(
            :course_content_course_ecosystem, course: course, created_at: Time.current - 1.hour
          )
        end
      end

      it 'prefers the course that was created in the newer ecosystem' do
        claimed_course = Timecop.freeze(current_time) do
          described_class[
            catalog_offering: offering, name: 'My New Preview Course', is_college: is_college
          ]
        end
        expect(claimed_course.id).to eq course.id
      end

      it 'falls back to the course created in the older ecosystem' do
        course.update_attribute :preview_claimed_at, Time.current

        claimed_course = Timecop.freeze(current_time) do
          described_class[
            catalog_offering: offering, name: 'My New Preview Course', is_college: is_college
          ]
        end
        expect(claimed_course.id).to eq old_ecosystem_course.id
      end
    end
  end

  context 'when no previews are pre-built' do
    it 'errors with api code and sends email' do
      result = described_class.call(
        catalog_offering: offering, name: 'My New Preview Course', is_college: is_college
      )
      expect(result.errors.first.code).to eq :no_preview_courses_available
      expect(ActionMailer::Base.deliveries.last.subject).to match('claim_preview_course.rb')
      expect(ActionMailer::Base.deliveries.last.body).to match("offering id #{offering.id}")
    end
  end
end
