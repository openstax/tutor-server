require 'rails_helper'
require 'vcr_helper'
require 'demo'

# Note: If you regenerate this cassette using production exercises, you must manually replace
#       all instances of the access token in the OAuth response and subsequent API request(s) with
#       <openstax_exercises_access_token>
RSpec.describe Demo, type: :routine, speed: :slow, vcr: VCR_OPTS do
  context 'with demo fixtures' do
    before(:all) do
      @old_max_processes = ENV['DEMO_MAX_PROCESSES']
      ENV['DEMO_MAX_PROCESSES'] = '0'
    end

    after(:all)  { ENV['DEMO_MAX_PROCESSES'] = @old_max_processes }

    before do
      # The demo rake task runs demo:content, demo:tasks and demo:work
      # For testing a lightweight import is performed so it completes faster
      # The customized import files for the specs are located in the fixtures directory
      stub_const(
        'Demo::Base::CONFIG_BASE_DIR', File.join(File.dirname(__FILE__), '../fixtures/demo')
      )
    end

    it "doesn't catch on fire" do
      expect { expect(Demo::Staff.call.errors).to be_empty }.to(
        change do
          User::Models::Profile.joins(:account).exists?(account: { username: 'admin' })
        end.from(false).to(true).and(
          change do
            User::Models::Profile.joins(:account).exists?(account: { username: 'content' })
          end.from(false).to(true).and(
            change do
              User::Models::Profile.joins(:account).exists?(account: { username: 'support' })
            end.from(false).to(true)
          )
        )
      )
      admin = User::Models::Profile.joins(:account).find_by!(account: { username: 'admin' })
      expect(admin.administrator).to be_present
      expect(admin.content_analyst).to be_present
      expect(admin.customer_service).to be_present
      content = User::Models::Profile.joins(:account).find_by!(account: { username: 'content' })
      expect(content.administrator).not_to be_present
      expect(content.content_analyst).to be_present
      expect(content.customer_service).not_to be_present
      support = User::Models::Profile.joins(:account).find_by!(account: { username: 'support' })
      expect(support.administrator).not_to be_present
      expect(support.content_analyst).not_to be_present
      expect(support.customer_service).to be_present

      expect { expect(Demo::Books.call.errors).to be_empty }.to(
        change do
          Content::Models::Ecosystem.where(
            title: 'APUSH (dc10e469-5816-411d-8ea3-39a9b0706a48@2.16)'
          ).count
        end.by(1).and(
          change { Catalog::Models::Offering.where(title: 'AP US History').count }.by(1)
        )
      )

      expect { expect(Demo::Courses.call.errors).to be_empty }.to(
        change { CourseProfile::Models::Course.where(name: 'AP US History Review').count }.by(1)
      )
      course = CourseProfile::Models::Course.order(created_at: :desc)
                                            .find_by!(name: 'AP US History Review')
      review_teacher = User::Models::Profile.joins(:account)
                                            .find_by!(account: { username: 'reviewteacher' })
      expect(review_teacher.roles.first.teacher.course).to eq course
      expect(review_teacher.account).to be_confirmed_faculty
      (1..6).each do |student_number|
        review_student = User::Models::Profile.joins(:account).find_by!(
          account: { username: "reviewstudent#{student_number}" }
        )
        expect(review_student.roles.first.student.course).to eq course
        expect(review_student.account).not_to be_confirmed_faculty
      end

      expect { expect(Demo::Tasks.call.errors).to be_empty }.to(
        change { Tasks::Models::TaskPlan.where(owner: course).count }.by(1)
      )
      task_plan = Tasks::Models::TaskPlan.find_by!(owner: course)
      expect(task_plan.type).to eq 'reading'
      expect(task_plan.tasks.count).to eq 8 # 6 students + 1 preview role for each period

      expect(Demo::Work.call.errors).to be_empty
      # We expect some tasks in each possible state
      tasks = task_plan.tasks.preload(:task_steps).reload
      expect(tasks.any? { |task| task.status == 'not_started' }).to eq true
      expect(tasks.any? { |task| task.status == 'in_progress' }).to eq true
      expect(tasks.any? { |task| task.status == 'completed' }).to eq true
      # The step status actually matches the task status
      tasks.reject(&:in_progress?).reject(&:completed?).each do |unstarted_task|
        expect(unstarted_task.task_steps.any?(&:completed?)).to eq false
      end
      tasks.select(&:in_progress?).each do |in_progress_task|
        expect(in_progress_task.task_steps.any?(&:completed?)).to eq true
        expect(in_progress_task.task_steps.all?(&:completed?)).to eq false
      end
      tasks.select(&:completed?).each do |completed_task|
        expect(completed_task.task_steps.all?(&:completed?)).to eq true
      end

      expect(Demo::Show.call.errors).to be_empty
    end
  end
end
