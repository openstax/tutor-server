require 'rails_helper'

RSpec.describe CourseProfile::ClaimPreviewCourse, type: :routine do
  let(:offering) { FactoryGirl.create :catalog_offering }
  let(:term)     { :preview }
  let(:year)     { Time.current.year }

  context 'with preview available' do
    let(:course) do
      CreateCourse[
        name: 'Unclaimed',
        term: term,
        year: year,
        time_zone: 'Indiana (East)',
        is_preview: true,
        is_college: true,
        catalog_offering: offering,
        estimated_student_count: 42
      ].tap { |course| course.update_attribute :is_preview_ready, true }
    end
    let!(:task_plan) do
      Timecop.freeze(Time.current - 3.months) do
        FactoryGirl.create :tasked_task_plan, owner: course
      end
    end

    it 'finds the course, task plans and tasks and updates their attributes' do
      current_time = Time.current
      claimed_course = Timecop.freeze(current_time) do
        CourseProfile::ClaimPreviewCourse[
          catalog_offering: offering, name: 'My New Preview Course'
        ]
      end
      expect(claimed_course.id).to eq course.id
      expect(claimed_course.name).to eq 'My New Preview Course'
      expect(claimed_course.preview_claimed_at).to eq current_time
      expect(claimed_course.starts_at).to eq current_time.monday - 2.weeks
      expect(claimed_course.ends_at).to eq current_time + 8.weeks - 1.second

      task_plan.tasking_plans.each do |tasking_plan|
        expect(tasking_plan.opens_at).to be_within(1).of(current_time)
        expect(tasking_plan.due_at).to be_within(1).of(current_time + 1.week)
      end

      task_plan.tasks.each do |task|
        expect(task.opens_at).to be_within(1).of(current_time)
        expect(task.due_at).to be_within(1).of(current_time + 1.week)
        expect(task.feedback_at).to be_nil
        expect(task.last_worked_at).to be_nil
      end
    end
  end

  context 'when no previews are pre-built' do
    it 'errors with api code and sends email' do
      result = CourseProfile::ClaimPreviewCourse.call(
        catalog_offering: offering, name: 'My New Preview Course'
      )
      expect(result.errors.first.code).to eq :no_preview_courses_available
      expect(ActionMailer::Base.deliveries.last.subject).to match('claim_preview_course.rb')
      expect(ActionMailer::Base.deliveries.last.body).to match("offering id #{offering.id}")
    end
  end

end
