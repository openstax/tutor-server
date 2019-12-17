require 'rails_helper'
require 'vcr_helper'

RSpec.describe WorkPreviewCourseTasks, type: :routine, speed: :medium do

  before(:all) do
    ecosystem = VCR.use_cassette('PopulatePreviewCourseContent/with_book', VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    end

    offering = FactoryBot.create :catalog_offering, ecosystem: ecosystem.to_model

    @course = FactoryBot.create :course_profile_course, :with_grading_templates,
                                                        offering: offering, is_preview: true
  end

  before do
    expect(described_class).to receive(:perform_later).with(course: @course).once
    PopulatePreviewCourseContent[course: @course]
    @course.reload
    expect(@course.periods.count).to eq 1
    expect(@course.students.count).to eq 6
  end

  it 'works the preview tasks in the course' do
    expect do
      result = described_class.call(course: @course)
    end.to  not_change { @course.periods.count }
       .and not_change { @course.students.count }
       .and not_change { Tasks::Models::TaskPlan.where(owner: @course).size }
       .and not_change { Tasks::Models::TaskPlan.where(owner: @course).flat_map(&:tasks).size }

    @course.periods.each do |period|
      student_roles = period.student_roles.sort_by(&:created_at)

      expect(student_roles.size).to eq 6

      # All roles except the third and sixth have completed everything
      (student_roles[0..1] + student_roles[3..4]).each do |role|
        role.taskings.each do |tasking|
          task = tasking.task

          task.task_steps.each do |task_step|
            expect(task_step).to be_completed

            next unless task_step.exercise?

            expect(task_step.tasked.free_response).to(
              eq (described_class::FREE_RESPONSE)
            )
          end
        end
      end
    end
  end

end
