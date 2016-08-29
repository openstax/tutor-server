require 'rails_helper'

RSpec.describe Admin::CoursesController, type: :controller do
  let(:admin) { FactoryGirl.create(:user, :administrator) }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    it 'assigns all CollectCourseInfo output to @course_infos' do
      CreateCourse[name: 'Hello World']
      get :index

      expect(assigns[:course_infos].count).to eq(1)
      expect(assigns[:course_infos].first.name).to eq('Hello World')
    end

    it 'passes the query params to SearchCourses along with order_by params' do
      expect(SearchCourses).to receive(:call).with(query: 'test', order_by: 'name').once.and_call_original
      get :index, query: 'test', order_by: 'name'
    end

    context "pagination" do
      context "when the are any results" do
        it "paginates the results" do
          3.times {FactoryGirl.create(:course_profile_profile, name: "Algebra #{rand(1000)}")}
          expect(CourseProfile::Models::Profile.count).to eq(3)

          get :index, page: 1, per_page: 2
          expect(assigns[:course_infos].length).to eq(2)

          get :index, page: 2, per_page: 2
          expect(assigns[:course_infos].length).to eq(1)
        end
      end

      context "when there are no results" do
        it "doesn't blow up" do
          expect(CourseProfile::Models::Profile.count).to eq(0)

          get :index, page: 1
          expect(response).to have_http_status :ok
        end
      end
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
    let(:physics)        { CreateCourse[name: 'Physics'] }
    let(:physics_period) { CreatePeriod[course: physics, name: '1st'] }

    let(:biology)        { CreateCourse[name: 'Biology'] }
    let(:biology_period) { CreatePeriod[course: biology, name: '3rd'] }

    let(:file_1) do
      fixture_file_upload('roster/test_courses_post_students_1.csv', 'text/csv')
    end

    let(:file_2) do
      fixture_file_upload('roster/test_courses_post_students_2.csv', 'text/csv')
    end

    let(:file_blankness) do
      fixture_file_upload('roster/test_courses_post_students_blankness.csv', 'text/csv')
    end

    let(:incomplete_file) do
      fixture_file_upload('roster/test_courses_post_students_incomplete.csv', 'text/csv')
    end

    it 'adds students to a course period' do
      expect {
        post :students, id: physics.id,
                        course: { period: physics_period.id },
                        student_roster: file_1
      }.to change { OpenStax::Accounts::Account.count }.by(3)
      expect(flash[:notice]).to eq('Student roster has been uploaded.')

      student_roster = GetCourseRoster.call(course: physics).outputs.roster[:students]
      csv = CSV.parse(file_1.open)
      names = csv[1..-1].flat_map(&:first)

      expect(student_roster.flat_map(&:first_name)).to match_array(names)
    end

    it 'reuses existing users for existing usernames' do
      expect {
        post :students, id: physics.id,
                        course: { period: physics_period.id },
                        student_roster: file_1
      }.to change { OpenStax::Accounts::Account.count }.by(3)

      expect {
        post :students, id: biology.id,
                        course: { period: biology_period.id },
                        student_roster: file_2
      }.to change { OpenStax::Accounts::Account.count }.by(1) # 2 in file but 1 reused

      # Carol B should be in both courses
      carol_b = User::User.find_by_username('carolb')
      expect(UserIsCourseStudent[user: carol_b, course: physics]).to eq true
      expect(UserIsCourseStudent[user: carol_b, course: biology]).to eq true
    end

    it 'does not add any students if username or password is missing' do
      expect {
        post :students, id: physics.id,
                        course: { period: physics_period.id },
                        student_roster: incomplete_file
      }.to change { OpenStax::Accounts::Account.count }.by(0)
      expect(flash[:error]).to eq([
        'Error uploading student roster',
        'On line 2, password is missing.',
        'On line 3, username is missing.',
        'On line 4, username is missing.',
        'On line 4, password is missing.'
      ])
    end

    it 'gives a nice error and no exception if has funky characters' do
      expect {
        post :students, id: physics.id,
                        course: { period: physics_period.id },
                        student_roster: file_blankness
      }.not_to raise_error

      expect(flash[:error]).to include 'Unquoted fields do not allow \r or \n (line 2).'
    end

    it 'gives a nice error if the file is blank' do
      expect {
        post :students, id: physics.id, course: { period: physics_period.id }
      }.not_to raise_error

      expect(flash[:error]).to include 'You must attach a file to upload.'
    end
  end

  describe 'GET #edit' do
    let(:course)    { FactoryGirl.create(:course_profile_profile, name: 'Physics I').course }
    let!(:eco_1)    {
      model = FactoryGirl.create(:content_book, title: 'Physics').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    }
    let(:book_1)    { eco_1.books.first }
    let(:uuid_1)    { book_1.uuid }
    let(:version_1) { book_1.version }
    let!(:eco_2)    {
      model = FactoryGirl.create(:content_book, title: 'Biology').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    }
    let(:book_2)    { eco_2.books.first }
    let(:uuid_2)    { book_2.uuid }
    let(:version_2) { book_2.version }
    let!(:course_ecosystem) {
      AddEcosystemToCourse.call(course: course, ecosystem: eco_1)
      CourseContent::Models::CourseEcosystem.where { entity_course_id == my { course.id } }
                                            .where { content_ecosystem_id == my { eco_1.id } }
                                            .first
    }

    it 'assigns extra course info' do
      get :edit, id: course.id

      expect(assigns[:profile].entity_course_id).to eq course.id
      expect(Set.new assigns[:periods]).to eq Set.new course.periods
      expect(Set.new assigns[:teachers]).to eq Set.new course.teachers
      expect(Set.new assigns[:ecosystems]).to eq Set.new Content::ListEcosystems[]
      expect(assigns[:course_ecosystem]).to eq GetCourseEcosystem[course: course]
    end

    it 'selects the correct ecosystem' do
      get :edit, id: course.id
      expect(assigns[:course_ecosystem]).to eq eco_1
      expect(assigns[:ecosystems]).to eq [eco_2, eco_1]
    end
  end

  describe 'DELETE #destroy' do
    let(:course)    { FactoryGirl.create(:course_profile_profile, name: 'Physics I').course }

    context 'destroyable course' do
      it 'delegates to the Admin::CoursesDestroy handler and displays a success message' do
        expect(Admin::CoursesDestroy).to receive(:handle).and_call_original

        delete :destroy, id: course.id

        expect(flash[:notice]).to include('The course has been deleted.')
      end
    end

    context 'non-destroyable course' do
      before { CreatePeriod[course: course] }

      it 'delegates to the Admin::CoursesDestroy handler and displays a failure message' do
        expect(Admin::CoursesDestroy).to receive(:handle).and_call_original

        delete :destroy, id: course.id

        expect(flash[:alert]).to(
          include('The course could not be deleted because it is not empty.')
        )
      end
    end
  end

  describe 'POST #set_ecosystem' do
    let(:course) { FactoryGirl.create(:course_profile_profile, name: 'Physics I').course }
    let(:eco_1)     {
      model = FactoryGirl.create(:content_book, title: 'Physics', version: '1').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    }
    let(:eco_2)     {
      model = FactoryGirl.create(:content_book, title: 'Biology', version: '2').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    }
    let!(:course_ecosystem) {
      AddEcosystemToCourse.call(course: course, ecosystem: eco_1)
      course.reload.course_ecosystems.first
    }

    context 'when the ecosystem is already being used' do
      it 'does not recreate the association' do
        post :set_ecosystem, id: course.id, ecosystem_id: eco_1.id
        ce = course.reload.course_ecosystems.first
        expect(ce).to eq course_ecosystem
        expect(flash[:notice]).to eq "Course ecosystem \"#{eco_1.title}\" is already selected for \"Physics I\""
      end
    end

    context 'when a new ecosystem is selected' do
      it 'adds the selected ecosystem as the first ecosystem' do
        post :set_ecosystem, id: course.id, ecosystem_id: eco_2.id
        ecosystems = course.reload.ecosystems.map do |ecosystem_model|
          strategy = ::Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
          ::Content::Ecosystem.new(strategy: strategy)
        end
        expect(ecosystems).to eq [eco_2, eco_1]
        expect(flash[:notice]).to(
          eq "Course ecosystem update to \"#{eco_2.title}\" queued for \"Physics I\""
        )
      end
    end

    context 'when the mapping is invalid' do
      it 'errors out with a Content::MapInvalidError so the background job fails immediately' do
        allow_any_instance_of(Content::Strategies::Generated::Map).to(
          receive(:is_valid).and_return(false)
        )
        expect{
          post :set_ecosystem, id: course.id, ecosystem_id: eco_2.id
        }.to raise_error(Content::MapInvalidError)
        expect(course.reload.ecosystems.count).to eq 1
        expect(flash[:error]).to be_blank
      end
    end
  end

  # Dante: Note that I think these might not actually work
  # calling multiple controller actions seems to break specs
  context 'disallowing baddies' do
    it 'disallows unauthenticated visitors' do
      allow(controller).to receive(:current_account) { nil }
      allow(controller).to receive(:current_user)    { nil }

      get :index
      expect(response).not_to be_success

      get :new
      expect(response).not_to be_success

      post :create
      expect(response).not_to be_success

      put :update, id: 1
      expect(response).not_to be_success

      delete :destroy, id: 1
      expect(response).not_to be_success
    end

    it 'disallows non-admin authenticated visitors' do
      controller.sign_in(FactoryGirl.create(:user))

      expect { get :index }.to raise_error(SecurityTransgression)
      expect { get :new }.to raise_error(SecurityTransgression)
      expect { post :create }.to raise_error(SecurityTransgression)
      expect { put :update, id: 1 }.to raise_error(SecurityTransgression)
      expect { delete :destroy, id: 1 }.to raise_error(SecurityTransgression)
    end
  end
end
