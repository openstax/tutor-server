require 'rails_helper'

RSpec.describe Admin::CoursesController do
  let(:admin) { FactoryGirl.create(:user_profile, :administrator) }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    it 'assigns all CollectCourseInfo output to @courses' do
      CreateCourse[name: 'Hello World']
      get :index

      expect(assigns[:courses].count).to eq(1)
      expect(assigns[:courses].first.name).to eq('Hello World')
    end
  end

  describe 'POST #create' do
    before do
      post :create, course: { name: 'Hello World' }
    end

    it 'creates a blank course profile' do
      expect(CourseProfile::Models::Profile.count).to eq(1)
    end

    it 'sets a flash notice' do
      expect(flash[:notice]).to eq('The course has been created.')
    end

    it 'redirects to /admin/courses' do
      expect(response).to redirect_to(admin_courses_path)
    end
  end

  describe 'POST #students' do
    let!(:physics) { CreateCourse[name: 'Physics'] }
    let!(:physics_period) { CreatePeriod[course: physics, name: '1st'] }

    let!(:biology) { CreateCourse[name: 'Biology'] }
    let!(:biology_period) { CreatePeriod[course: biology, name: '3rd'] }

    let!(:file_1) { fixture_file_upload('files/test_courses_post_students_1.csv', 'text/csv') }
    let!(:file_2) { fixture_file_upload('files/test_courses_post_students_2.csv', 'text/csv') }
    let!(:incomplete_file) { fixture_file_upload('files/test_courses_post_students_incomplete.csv', 'text/csv') }

    it 'adds students to a course period' do
      expect {
        post :students, id: physics.id, course: { period: physics_period.id }, student_roster: file_1
      }.to change { OpenStax::Accounts::Account.count }.by(3)
      expect(flash[:notice]).to eq('Student roster has been uploaded.')

      student_roster = GetStudentRoster[course: physics]
      expect(student_roster.length).to eq(3)
      expect(student_roster[0].first_name).to eq('Carol')
      expect(student_roster[1].first_name).to eq('Melissa')
      expect(student_roster[2].first_name).to eq('Alexander')
    end

    it 'reuses existing users for existing usernames' do
      # FactoryGirl.create :user_profile, username: 'alexh'
      expect {
        post :students, id: physics.id, course: { period: physics_period.id }, student_roster: file_1
      }.to change { OpenStax::Accounts::Account.count }.by(3)

      expect {
        post :students, id: biology.id, course: { period: biology_period.id }, student_roster: file_2
      }.to change { OpenStax::Accounts::Account.count }.by(1) # 2 in file but 1 reused

      # Carol B should be in both courses
      expect(UserIsCourseStudent[user: Entity::User.second, course: physics]).to eq true
      expect(UserIsCourseStudent[user: Entity::User.second, course: biology]).to eq true
    end

    it 'does not add any students if username or password is missing' do
      expect {
        post :students, id: physics.id, course: { period: physics_period.id }, student_roster: incomplete_file
      }.to change { OpenStax::Accounts::Account.count }.by(0)
      expect(flash[:error]).to eq([
        'Error uploading student roster',
        'On line 2, password is missing.',
        'On line 3, username is missing.',
        'On line 4, username is missing.',
        'On line 4, password is missing.'
      ])
    end
  end

  describe 'GET #edit' do
    let!(:course)    { FactoryGirl.create(:course_profile_profile, name: 'Physics I').course }
    let!(:eco_1)     { FactoryGirl.create(:content_book, title: 'Physics').ecosystem }
    let!(:book_1)    { eco_1.books.first }
    let!(:uuid_1)    { book_1.uuid }
    let!(:version_1) { book_1.version }
    let!(:eco_2)     { FactoryGirl.create(:content_book, title: 'Biology').ecosystem }
    let!(:book_2)    { eco_2.books.first }
    let!(:uuid_2)    { book_2.uuid }
    let!(:version_2) { book_2.version }
    let!(:course_ecosystem) {
      AddEcosystemToCourse.call(course: course, ecosystem: eco_1)
      CourseContent::Models::CourseEcosystem.where { entity_course_id == my { course.id } }
                                            .where { content_ecosystem_id == my { eco_1.id } }
                                            .first
    }

    it 'selects the correct ecosystem' do
      get :edit, id: course.id
      expect(assigns[:course_ecosystem]).to eq eco_1
      expect(assigns[:ecosystems].sort { |a, b| a.id <=> b.id }).to eq([
        {
          'id' => eco_1.id,
          'books' => [
            {
              'id' => book_1.id,
              'title' => 'Physics',
              'url' => book_1.url,
              'uuid' => uuid_1,
              'version' => version_1,
              'title_with_id' => "Physics (#{uuid_1}@#{version_1})"
            }
          ]
        },
        {
          'id' => eco_2.id,
          'books' => [
            {
              'id' => book_2.id,
              'title' => 'Biology',
              'url' => book_2.url,
              'uuid' => uuid_2,
              'version' => version_2,
              'title_with_id' => "Biology (#{uuid_2}@#{version_2})"
            }
          ]
        }
      ])
    end
  end

  describe 'POST #set_ecosystem' do
    let!(:course) { FactoryGirl.create(:course_profile_profile, name: 'Physics I').course }
    let!(:eco_1)  { FactoryGirl.create(:content_book, title: 'Physics').ecosystem }
    let!(:eco_2)  { FactoryGirl.create(:content_book, title: 'Biology').ecosystem }
    let!(:course_ecosystem) {
      AddEcosystemToCourse.call(course: course, ecosystem: ecosystem_1)
      course.reload.course_ecosystems.first
    }

    context 'when the ecosystem is already being used' do
      it 'does not recreate the association' do
        post :set_ecosystem, id: course.id, ecosystem_id: eco_1.id
        ce = course.reload.course_ecosystems.first
        expect(ce.id).to eq course_ecosystem.id
        expect(flash[:notice]).to eq 'Course ecosystem "Physics" is already selected for "Physics I"'
      end
    end

    context 'when a new ecosystem is selected' do
      it 'removes the existing association and creates a new one' do
        post :set_book, id: course.id, ecosystem_id: eco_2.id
        ecos = course.reload.ecosystems
        expect(ecos).to eq [eco_2]
        expect(flash[:notice]).to eq 'Course ecosystem "Biology" selected for "Physics I"'
      end
    end
  end

  context 'disallowing baddies' do
    it 'disallows unauthenticated visitors' do
      allow(controller).to receive(:current_account) { nil }
      allow(controller).to receive(:current_user) { nil }

      get :index
      expect(response).not_to be_success

      get :new
      expect(response).not_to be_success

      post :create
      expect(response).not_to be_success

      put :update, id: 1
      expect(response).not_to be_success
    end

    it 'disallows non-admin authenticated visitors' do
      non_admin = FactoryGirl.create(:user_profile)
      controller.sign_in(non_admin)

      expect { get :index }.to raise_error(SecurityTransgression)
      expect { get :new }.to raise_error(SecurityTransgression)
      expect { post :create }.to raise_error(SecurityTransgression)
      expect { put :update, id: 1 }.to raise_error(SecurityTransgression)
    end
  end
end
