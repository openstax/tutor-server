require 'rails_helper'

RSpec.describe Admin::CoursesController, type: :controller do
  let(:admin) { FactoryBot.create(:user, :administrator) }

  before      { controller.sign_in(admin) }

  context 'GET #index' do
    it 'assigns all CollectCourseInfo output to @course_infos' do
      FactoryBot.create :course_profile_course, name: 'Hello World'

      get :index

      expect(assigns[:course_infos].count).to eq(1)
      expect(assigns[:course_infos].first.name).to eq('Hello World')
    end

    it 'passes the query params to SearchCourses along with order_by params' do
      expect(SearchCourses).to(
        receive(:call).with(query: 'test', order_by: 'name').once.and_call_original
      )
      get :index, query: 'test', order_by: 'name'
    end

    context "pagination" do
      it "paginates the results" do
        3.times { FactoryBot.create(:course_profile_course) }

        get :index, page: 1, per_page: 2
        expect(assigns[:course_infos].length).to eq(2)

        get :index, page: 2, per_page: 2
        expect(assigns[:course_infos].length).to eq(1)
      end

      context "with more than 25 courses" do
        before(:each) do
          26.times { FactoryBot.create(:course_profile_course) }
        end

        context "with per_page param" do
          context "equal to \"all\"" do
            it "assigns all courses" do
              get :index, page: 1, per_page: "all"
              expect(assigns[:course_infos].length).to eq(26)
            end
          end

          context "equal to nil" do
            it "assigns 25 courses per page" do
              get :index, page: 1, per_page: nil
              expect(assigns[:course_infos].length).to eq(25)

              get :index, page: 2, per_page: nil
              expect(assigns[:course_infos].length).to eq(1)
            end
          end
        end
      end

      context "when there are no results" do
        it "returns http status OK" do
          expect(CourseProfile::Models::Course.count).to eq(0)

          get :index, page: 1
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  context 'POST #create' do
    let(:num_sections) { 2 }

    let(:request) do
      post :create, course: {
        name: 'Hello World',
        term: CourseProfile::Models::Course.terms.keys.sample,
        year: Time.current.year,
        is_test: false,
        is_preview: false,
        is_concept_coach: false,
        is_college: true,
        num_sections: num_sections,
        catalog_offering_id: FactoryBot.create(:catalog_offering).id
      }
    end

    it 'creates a course' do
      expect{request}.to change{CourseProfile::Models::Course.count}.by(1)
    end

    it 'creates the specified number of sections' do
      expect{request}.to change{CourseMembership::Models::Period.count}.by(num_sections)
    end

    it 'sets a flash notice' do
      request
      expect(flash[:notice]).to eq('The course has been created.')
    end

    it 'redirects to /admin/courses' do
      request
      expect(response).to redirect_to(admin_courses_path)
    end
  end

  context 'POST #roster' do
    let(:physics)        { FactoryBot.create :course_profile_course }
    let(:physics_period) { FactoryBot.create :course_membership_period, course: physics }

    let(:biology)        { FactoryBot.create :course_profile_course }
    let(:biology_period) { FactoryBot.create :course_membership_period, course: biology }

    let(:file_1) do
      fixture_file_upload('roster/test_courses_post_roster_1.csv', 'text/csv')
    end

    let(:file_2) do
      fixture_file_upload('roster/test_courses_post_roster_2.csv', 'text/csv')
    end

    let(:file_blank_lines) do
      fixture_file_upload('roster/test_courses_post_roster_blank_lines.csv', 'text/csv')
    end

    let(:incomplete_file) do
      fixture_file_upload('roster/test_courses_post_roster_incomplete.csv', 'text/csv')
    end

    it 'adds students to a course period' do
      expect do
        post :roster, id: physics.id,
                      period: physics_period.id,
                      roster: file_1
      end.to change { OpenStax::Accounts::Account.count }.by(3)
      expect(flash[:notice]).to eq('Student roster import has been queued.')

      student_roster = GetCourseRoster.call(course: physics).outputs.roster[:students]
      csv = CSV.parse(file_1.open)
      names = csv[1..-1].flat_map(&:first)

      expect(student_roster.flat_map(&:first_name)).to match_array(names)
    end

    it 'reuses existing users for existing usernames' do
      expect do
        post :roster, id: physics.id,
                      period: physics_period.id,
                      roster: file_1
      end.to change { OpenStax::Accounts::Account.count }.by(3)

      expect do
        post :roster, id: biology.id,
                      period: biology_period.id,
                      roster: file_2
      end.to change { OpenStax::Accounts::Account.count }.by(1) # 2 in file but 1 reused

      # Carol B should be in both courses
      carol_b = User::User.find_by_username('carolb')
      expect(UserIsCourseStudent[user: carol_b, course: physics]).to eq true
      expect(UserIsCourseStudent[user: carol_b, course: biology]).to eq true
    end

    it 'does not add any students if username or password is missing' do
      expect do
        post :roster, id: physics.id,
                      period: physics_period.id,
                      roster: incomplete_file
      end.to change { OpenStax::Accounts::Account.count }.by(0)
      expect(flash[:error]).to eq([
        'Invalid Roster: On line 2, password is missing.',
        'Invalid Roster: On line 3, username is missing.',
        'Invalid Roster: On line 4, username is missing.',
        'Invalid Roster: On line 4, password is missing.'
      ])
    end

    it 'gives a nice error and no exception if has funky characters' do
      expect do
        post :roster, id: physics.id,
                      period: physics_period.id,
                      roster: file_blank_lines
      end.not_to raise_error

      expect(flash[:error]).to include 'Unquoted fields do not allow \r or \n (line 2).'
    end

    it 'gives a nice error if the period is blank' do
      expect { post :roster, id: physics.id, roster: file_1 }.not_to raise_error

      expect(flash[:error]).to include 'You must select a period to upload to.'
    end

    it 'gives a nice error if an invalid period is selected' do
      expect do
        post :roster, id: physics.id, period: biology_period.id, roster: file_1
      end.not_to raise_error

      expect(flash[:error]).to include 'The selected period could not be found.'
    end

    it 'gives a nice error if the file is blank' do
      expect { post :roster, id: physics.id, period: physics_period.id }.not_to raise_error

      expect(flash[:error]).to include 'You must attach a file to upload.'
    end
  end

  context 'GET #edit' do
    let!(:eco_1)            do
      model = FactoryBot.create(:content_book, title: 'Physics').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    end
    let(:catalog_offering)  do
      FactoryBot.create :catalog_offering, ecosystem: eco_1.to_model
    end
    let(:course)            do
      FactoryBot.create :course_profile_course, name: 'Physics I', offering: catalog_offering
    end
    let(:book_1)            { eco_1.books.first }
    let(:uuid_1)            { book_1.uuid }
    let(:version_1)         { book_1.version }
    let!(:eco_2)            do
      model = FactoryBot.create(:content_book, title: 'Biology').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    end
    let(:book_2)            { eco_2.books.first }
    let(:uuid_2)            { book_2.uuid }
    let(:version_2)         { book_2.version }
    let!(:course_ecosystem) do
      AddEcosystemToCourse.call(course: course, ecosystem: eco_1)
      CourseContent::Models::CourseEcosystem.where { course_profile_course_id == my { course.id } }
                                            .where { content_ecosystem_id == my { eco_1.id } }
                                            .first
    end

    it 'assigns extra course info' do
      get :edit, id: course.id

      expect(assigns[:course].id).to eq course.id
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

  context 'DELETE #destroy' do
    let(:course) { FactoryBot.create :course_profile_course }

    context 'destroyable course' do
      it 'delegates to the Admin::CoursesDestroy handler and displays a success message' do
        expect(Admin::CoursesDestroy).to receive(:handle).and_call_original

        delete :destroy, id: course.id

        expect(flash[:notice]).to include('The course has been deleted.')
      end
    end

    context 'non-destroyable course' do
      before { FactoryBot.create :course_membership_period, course: course }

      it 'delegates to the Admin::CoursesDestroy handler and displays a failure message' do
        expect(Admin::CoursesDestroy).to receive(:handle).and_call_original

        delete :destroy, id: course.id

        expect(flash[:alert]).to(
          include('The course could not be deleted because it is not empty.')
        )
      end
    end
  end

  context 'POST #set_ecosystem' do
    let(:course)            do
      FactoryBot.create(:course_profile_course, :without_ecosystem, name: 'Physics I')
    end
    let(:eco_1)             do
      model = FactoryBot.create(:content_book, title: 'Physics', version: '1').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    end
    let(:eco_2)             do
      model = FactoryBot.create(:content_book, title: 'Biology', version: '2').ecosystem
      strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
      ::Content::Ecosystem.new(strategy: strategy)
    end
    let!(:course_ecosystem) do
      AddEcosystemToCourse.call(course: course, ecosystem: eco_1)
      course.course_ecosystems.first
    end

    context 'when the ecosystem is already being used' do
      it 'does not recreate the association' do
        post :set_ecosystem, id: course.id, ecosystem_id: eco_1.id
        ce = course.course_ecosystems.first
        expect(ce).to eq course_ecosystem
        expect(flash[:notice]).to(
          eq "Course ecosystem \"#{eco_1.title}\" is already selected for \"Physics I\""
        )
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
      controller.sign_in(FactoryBot.create(:user))

      expect { get :index }.to raise_error(SecurityTransgression)
      expect { get :new }.to raise_error(SecurityTransgression)
      expect { post :create }.to raise_error(SecurityTransgression)
      expect { put :update, id: 1 }.to raise_error(SecurityTransgression)
      expect { delete :destroy, id: 1 }.to raise_error(SecurityTransgression)
    end
  end
end
