require 'rails_helper'
require 'vcr_helper'

RSpec.describe "fix_multi_enrollments", type: :rake do
  include_context "rake"

  before(:all) do
    ecosystem = VCR.use_cassette('GetConceptCoach/with_book', VCR_OPTS) do
      OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/') do
        FetchAndImportBookAndCreateEcosystem[book_cnx_id: 'f10533ca-f803-490d-b935-88899941197f']
      end
    end

    @book = ecosystem.books.first

    page_model_1 = Content::Models::Page.find_by(title: 'Sample module 1')
    page_model_2 = Content::Models::Page.find_by(title: 'The Science of Biology')
    page_model_3 = Content::Models::Page.find_by(title: 'Sample module 2')
    page_model_4 = Content::Models::Page.find_by(
      title: 'Atoms, Isotopes, Ions, and Molecules: The Building Blocks'
    )

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)
    @page_3 = Content::Page.new(strategy: page_model_3.reload.wrap)
    @page_4 = Content::Page.new(strategy: page_model_4.reload.wrap)

    @school = FactoryGirl.create :school_district_school
    @course = FactoryGirl.create :course_profile_course, :without_ecosystem,
                                 school: @school, is_concept_coach: true
    @old_period = FactoryGirl.create :course_membership_period, course: @course
    old_period_wrapper = CourseMembership::Period.new(strategy: @old_period.wrap)

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]

    @user_1 = FactoryGirl.create(:user)
    @user_2 = FactoryGirl.create(:user)
    @user_3 = FactoryGirl.create(:user)

    @old_role_1 = AddUserAsPeriodStudent[user: @user_1, period: old_period_wrapper]
    @old_role_2 = AddUserAsPeriodStudent[user: @user_2, period: old_period_wrapper]

    @teacher_role = AddUserAsCourseTeacher[user: @user_3, course: @course]

    @task_1 = GetConceptCoach[user: @user_1, book_uuid: @book.uuid, page_uuid: @page_1.uuid]
    @task_2 = GetConceptCoach[user: @user_2, book_uuid: @book.uuid, page_uuid: @page_1.uuid]
    @task_3 = GetConceptCoach[user: @user_1, book_uuid: @book.uuid, page_uuid: @page_2.uuid]

    @old_period.destroy

    @new_period = FactoryGirl.create :course_membership_period, course: @course
    new_period_wrapper = CourseMembership::Period.new(strategy: @new_period.wrap)
    @new_role = AddUserAsPeriodStudent[user: @user_1, period: new_period_wrapper]

    # Let's pretend @task_3 happened after the new registration but got assigned to @old_role_1
    @task_3.update_attribute :created_at, Time.current
    @task_3.taskings.first.update_attribute :created_at, Time.current
  end

  after(:all)  { FileUtils.rm_f 'tmp/multi-enrollments.csv' }

  context 'dry run' do
    it "does not modify any tasks or taskings" do
      expect(@task_3.reload.taskings.first.role).to eq @old_role_1
      expect(@task_3.concept_coach_task.role).to eq @old_role_1

      expect(capture_stdout{call}).to be_blank

      expect(@task_3.reload.taskings.first.role).to eq @old_role_1
      expect(@task_3.concept_coach_task.role).to eq @old_role_1
    end

    it "writes fixed user, teacher and school names to a csv file" do
      expect(capture_stdout{call}).to be_blank

      content = File.open('tmp/multi-enrollments.csv', 'r').read
      expect(content).to include(@user_1.name.strip)
      expect(content).to include(@user_3.name.strip)
      expect(content).to include(@school.name)

      expect(content).not_to include(@user_2.name.strip)
    end
  end

  context 'real run' do
    it "fixes tasks assigned to the wrong user roles" do
      expect(@task_3.reload.taskings.first.role).to eq @old_role_1
      expect(@task_3.concept_coach_task.role).to eq @old_role_1

      expect(capture_stdout{call('real')}).to be_blank

      expect(@task_3.reload.taskings.first.role).to eq @new_role
      expect(@task_3.concept_coach_task.role).to eq @new_role
    end

    it "writes fixed user, teacher and school names to a csv file" do
      expect(capture_stdout{call('real')}).to be_blank

      content = File.open('tmp/multi-enrollments.csv', 'r').read
      expect(content).to include(@user_1.name.strip)
      expect(content).to include(@user_3.name.strip)
      expect(content).to include(@school.name)

      expect(content).not_to include(@user_2.name.strip)
    end
  end

end
