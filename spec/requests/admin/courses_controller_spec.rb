require 'rails_helper'

RSpec.describe Admin::CoursesController, type: :request do
  let(:admin) { FactoryBot.create(:user_profile, :administrator) }

  before      {
    sign_in! admin
    # click_button 'input[type="submit"]'
  }

  context 'GET #index' do
    it 'assigns all CollectCourseInfo output to @course_infos' do
      FactoryBot.create :course_profile_course, name: 'Hello World'

      get admin_courses_url(query: '')

      expect(assigns[:course_infos].count).to eq(1)
      expect(assigns[:course_infos].first.name).to eq('Hello World')
    end

    it 'passes the query params to SearchCourses along with order_by params' do
      expect(SearchCourses).to(
        receive(:call).with(query: 'test', order_by: 'name').once.and_call_original
      )
      get admin_courses_url, params: { query: 'test', order_by: 'name' }
    end

    context 'pagination' do
      it 'paginates the results' do
        3.times { FactoryBot.create(:course_profile_course) }

        get admin_courses_url, params: { query: '', page: 1, per_page: 2 }
        expect(assigns[:course_infos].length).to eq(2)

        get admin_courses_url, params: { query: '', page: 2, per_page: 2 }
        expect(assigns[:course_infos].length).to eq(1)
      end

      context 'with more than 25 courses' do
        before(:each) { 26.times { FactoryBot.create(:course_profile_course) } }

        context 'with per_page param equal to "all"' do
          it 'assigns all courses to the first page' do
            get admin_courses_url, params: { query: '', page: 1, per_page: 'all' }
            expect(assigns[:course_infos].length).to eq(26)
          end
        end

        context 'with no per_page param' do
          it 'assigns 25 courses per page' do
            get admin_courses_url, params: { query: '', page: 1 }
            expect(assigns[:course_infos].length).to eq(25)
          end

          it 'can show other pages' do
            get admin_courses_url, params: { query: '', page: 2 }
            expect(assigns[:course_infos].length).to eq(1)
          end
        end
      end

      context 'when there are no results' do
        it 'returns http status OK' do
          expect(CourseProfile::Models::Course.count).to eq(0)

          get admin_courses_url, params: { query: '', page: 1 }
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  context 'POST #create' do
    let(:num_sections) { 2 }

    let(:req) do
      post admin_courses_url, params: {
        course: {
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
      }
    end

    it 'creates a course' do
      expect { req }.to change {CourseProfile::Models::Course.count}.by(1)
    end

    it 'creates the specified number of sections' do
      expect { req }.to change {CourseMembership::Models::Period.count}.by(num_sections)
    end

    it 'sets a flash notice' do
      req
      expect(flash[:notice]).to eq('The course has been created.')
    end

    it 'redirects to /admin/courses' do
      req
      expect(response).to redirect_to(admin_courses_url)
    end
  end

  context 'GET #edit' do
    let!(:eco_1)            do
      FactoryBot.create(:content_book, title: 'Physics').ecosystem
    end
    let(:catalog_offering)  do
      FactoryBot.create :catalog_offering, ecosystem: eco_1
    end
    let(:course)            do
      FactoryBot.create :course_profile_course, name: 'Physics I', offering: catalog_offering
    end
    let(:book_1)            { eco_1.books.first }
    let(:uuid_1)            { book_1.uuid }
    let(:version_1)         { book_1.version }
    let!(:eco_2)            do
      FactoryBot.create(:content_book, title: 'Biology').ecosystem
    end
    let(:book_2)            { eco_2.books.first }
    let(:uuid_2)            { book_2.uuid }
    let(:version_2)         { book_2.version }
    let!(:course_ecosystem) do
      AddEcosystemToCourse.call(course: course, ecosystem: eco_1)
      CourseContent::Models::CourseEcosystem.where(course_profile_course_id: course.id)
                                            .where(content_ecosystem_id: eco_1.id)
                                            .first
    end

    it 'assigns extra course info' do
      get edit_admin_course_url(course.id)

      expect(assigns[:course].id).to eq course.id
      expect(Set.new assigns[:periods]).to eq Set.new course.periods
      expect(Set.new assigns[:teachers]).to eq Set.new course.teachers
      expect(Set.new assigns[:ecosystems]).to eq Set.new Content::ListEcosystems[]
      expect(assigns[:course_ecosystem]).to eq GetCourseEcosystem[course: course]
    end

    it 'selects the correct ecosystem' do
      get edit_admin_course_url(course.id)
      expect(assigns[:course_ecosystem]).to eq eco_1
      expect(assigns[:ecosystems]).to eq [eco_2, eco_1]
    end
  end

  context 'DELETE #unpair_lms' do
    let(:course) { FactoryBot.create :course_profile_course }
    it 'calls unpair routine' do
      expect_any_instance_of(Lms::RemoveLastCoursePairing).to(
        receive(:call).with(course: course)
      )
      delete unpair_lms_admin_course_url(course.id)
    end
  end

  context 'DELETE #destroy' do
    let(:course) { FactoryBot.create :course_profile_course }

    context 'destroyable course' do
      it 'delegates to the Admin::CoursesDestroy handler and displays a success message' do
        expect(Admin::CoursesDestroy).to receive(:handle).and_call_original

        delete admin_course_url(course.id)

        expect(flash[:notice]).to include('The course has been deleted.')
      end
    end

    context 'non-destroyable course' do
      before { FactoryBot.create :course_membership_period, course: course }

      it 'delegates to the Admin::CoursesDestroy handler and displays a failure message' do
        expect(Admin::CoursesDestroy).to receive(:handle).and_call_original

        delete admin_course_url(course.id)

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
      FactoryBot.create(:content_book, title: 'Physics', version: '1').ecosystem
    end
    let(:eco_2)             do
      FactoryBot.create(:content_book, title: 'Biology', version: '2').ecosystem
    end
    let!(:course_ecosystem) do
      AddEcosystemToCourse.call(course: course, ecosystem: eco_1)
      course.course_ecosystems.first
    end

    context 'when the ecosystem is already being used' do
      it 'does not recreate the association' do
        post set_ecosystem_admin_course_url(course.id), params: {  ecosystem_id: eco_1.id }
        ce = course.course_ecosystems.first
        expect(ce).to eq course_ecosystem
        expect(flash[:notice]).to(
          eq "Course ecosystem \"#{eco_1.title}\" is already selected for \"Physics I\""
        )
      end
    end

    context 'when a new ecosystem is selected' do
      it 'adds the selected ecosystem as the first ecosystem' do
        post set_ecosystem_admin_course_url(course.id), params: { ecosystem_id: eco_2.id }
        ecosystems = course.reload.ecosystems
        expect(ecosystems).to eq [eco_2, eco_1]
        expect(flash[:notice]).to(
          eq "Course ecosystem update to \"#{eco_2.title}\" queued for \"Physics I\""
        )
      end
    end

    context 'when the mapping is invalid' do
      it 'errors out with a Content::MapInvalidError so the background job fails immediately' do
        allow_any_instance_of(Content::Map).to(
          receive(:is_valid).and_return(false)
        )
        expect do
          post set_ecosystem_admin_course_url(course.id), params: { ecosystem_id: eco_2.id }
        end.to raise_error(Content::MapInvalidError)
        expect(course.reload.ecosystems.count).to eq 1
        expect(flash[:error]).to be_blank
      end
    end
  end

  context 'disallowing baddies' do
    it 'disallows unauthenticated visitors' do
      sign_out!

      get admin_courses_url
      expect(response).not_to be_successful
    end

    it 'disallows non-admin authenticated visitors' do
      sign_in! FactoryBot.create(:user_profile)

      expect { get admin_courses_url }.to raise_error(SecurityTransgression)
      expect { get new_admin_course_url }.to raise_error(SecurityTransgression)
      expect { post admin_courses_url }.to raise_error(SecurityTransgression)
      expect { put admin_course_url(1) }.to raise_error(SecurityTransgression)
      expect { delete admin_course_url(1) }.to raise_error(SecurityTransgression)
    end
  end
end
