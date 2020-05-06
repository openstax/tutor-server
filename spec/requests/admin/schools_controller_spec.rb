require 'rails_helper'

RSpec.describe Admin::SchoolsController, type: :request do
  let(:admin)  { FactoryBot.create(:user_profile, :administrator) }
  let(:school) { FactoryBot.build :school_district_school, name: 'Hello World' }

  before { sign_in! admin }

  context 'GET #index' do
    before { school.save! }

    it 'assigns @schools and @page_header' do
      get admin_schools_url

      expect(assigns[:schools].count).to eq(1)
      expect(assigns[:schools].first.name).to eq('Hello World')
      expect(assigns[:page_header]).to eq("Manage schools")
    end
  end

  context 'GET #new' do
    it 'assigns @school and @page_header' do
      get new_admin_school_url

      expect(assigns[:school]).to be_present
      expect(assigns[:page_header]).to eq("Create a school")
    end
  end

  context 'POST #create' do
    before { school.save! }

    context 'unused name' do
      it 'creates the school and redirects to #index' do
        expect do
          post admin_schools_url, params: {
            school: { name: 'Hello World', school_district_district_id: nil }
          }
        end.to change { SchoolDistrict::Models::School.count }.by(1)

        expect(response).to redirect_to(admin_schools_url)

        school = SchoolDistrict::Models::School.order(:id).last
        expect(school.name).to eq 'Hello World'
      end
    end

    context 'used name' do
      it 'displays an error message and assigns @school and @page_header' do
        expect do
          post admin_schools_url, params: {
            school: { name: 'Hello World', school_district_district_id: school.district.id }
          }
        end.not_to change { SchoolDistrict::Models::School.count }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:error]).to include('Name has already been taken')
        expect(assigns[:school]).to be_present
        expect(assigns[:page_header]).to eq("Create a school")
      end
    end
  end

  context 'GET #edit' do
    before { school.save! }

    it 'assigns @school and @page_header' do
      get edit_admin_school_url(school.id)

      expect(assigns[:school]).to be_present
      expect(assigns[:page_header]).to eq("Edit school")
    end
  end

  context 'PATCH #update' do
    before { school.save! }

    context 'unused name' do
      it 'updates the school and redirects to #index' do
        patch admin_school_url(school.id), params: {
          school: { name: 'Hello Again', school_district_district_id: school.district.id }
        }

        expect(response).to redirect_to(admin_schools_url)
        expect(school.reload.name).to eq 'Hello Again'
      end
    end

    context 'used name' do
      before { FactoryBot.create :school_district_school, name: 'Hello Again',
                                                           district: school.district }

      it 'displays an error message and assigns @school and @page_header' do
        patch admin_school_url(school.id), params: {
          school: { name: 'Hello Again', school_district_district_id: school.district.id }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:error]).to include('Name has already been taken')
        expect(assigns[:school]).to be_present
        expect(assigns[:page_header]).to eq("Edit school")
        expect(school.reload.name).to eq 'Hello World'
      end
    end
  end

  context 'DELETE #destroy' do
    before { school.save! }

    context 'without schools' do
      it 'deletes the school and redirects to #index' do
        expect { delete admin_school_url(school.id) }.to(
          change { SchoolDistrict::Models::School.count }.by(-1)
        )

        expect(response).to redirect_to(admin_schools_url)
      end
    end

    context 'with courses' do
      before { FactoryBot.create :course_profile_course, school: school }

      it 'redirects to #index and displays an error message' do
        expect { delete admin_school_url(school.id) }.not_to(
          change { SchoolDistrict::Models::School.count }
        )

        expect(response).to redirect_to(admin_schools_url)
        expect(flash[:error]).to include('Cannot delete a school that has courses.')
        expect(school.reload).to be_persisted
      end
    end
  end
end
