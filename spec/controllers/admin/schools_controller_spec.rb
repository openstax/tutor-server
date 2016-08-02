require 'rails_helper'

RSpec.describe Admin::SchoolsController, type: :controller do
  let(:admin)  { FactoryGirl.create(:user, :administrator) }
  let(:school) { FactoryGirl.build :school_district_school, name: 'Hello World' }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    before { school.save! }

    it 'assigns @schools and @page_header' do
      get :index

      expect(assigns[:schools].count).to eq(1)
      expect(assigns[:schools].first.name).to eq('Hello World')
      expect(assigns[:page_header]).to eq("Manage schools")
    end
  end

  describe 'GET #new' do
    it 'assigns @school and @page_header' do
      get :new

      expect(assigns[:school]).to be_present
      expect(assigns[:page_header]).to eq("Create a school")
    end
  end

  describe 'POST #create' do
    before { school.save! }

    context 'unused name' do
      it 'creates the school and redirects to #index' do
        expect { post :create, school: { name: 'Hello World',
                                         school_district_district_id: nil } }.to(
          change { SchoolDistrict::Models::School.count }.by(1)
        )

        expect(response).to redirect_to(admin_schools_path)

        school = SchoolDistrict::Models::School.order(:id).last
        expect(school.name).to eq 'Hello World'
      end
    end

    context 'used name' do
      it 'displays an error message and assigns @school and @page_header' do
        expect { post :create, school: { name: 'Hello World',
                                         school_district_district_id: school.district.id } }.not_to(
          change { SchoolDistrict::Models::School.count }
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:error]).to include('Name has already been taken')
        expect(assigns[:school]).to be_present
        expect(assigns[:page_header]).to eq("Create a school")
      end
    end
  end

  describe 'GET #edit' do
    before { school.save! }

    it 'assigns @school and @page_header' do
      get :edit, id: school.id

      expect(assigns[:school]).to be_present
      expect(assigns[:page_header]).to eq("Edit school")
    end
  end

  describe 'PATCH #update' do
    before { school.save! }

    context 'unused name' do
      it 'updates the school and redirects to #index' do
        patch :update, id: school.id,
                       school: { name: 'Hello Again',
                                 school_district_district_id: school.district.id }

        expect(response).to redirect_to(admin_schools_path)
        expect(school.reload.name).to eq 'Hello Again'
      end
    end

    context 'used name' do
      before { FactoryGirl.create :school_district_school, name: 'Hello Again',
                                                           district: school.district }

      it 'displays an error message and assigns @school and @page_header' do
        patch :update, id: school.id,
                       school: { name: 'Hello Again',
                                 school_district_district_id: school.district.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:error]).to include('Name has already been taken')
        expect(assigns[:school]).to be_present
        expect(assigns[:page_header]).to eq("Edit school")
        expect(school.reload.name).to eq 'Hello World'
      end
    end
  end

  describe 'DELETE #destroy' do
    before { school.save! }

    context 'without schools' do
      it 'deletes the school and redirects to #index' do
        expect { delete :destroy, id: school.id }.to(
          change { SchoolDistrict::Models::School.count }.by(-1)
        )

        expect(response).to redirect_to(admin_schools_path)
      end
    end

    context 'with courses' do
      before { FactoryGirl.create :course_profile_profile, school: school }

      it 'redirects to #index and displays an error message' do
        expect { delete :destroy, id: school.id }.not_to(
          change { SchoolDistrict::Models::School.count }
        )

        expect(response).to redirect_to(admin_schools_path)
        expect(flash[:error]).to include('Cannot delete a school that has courses.')
        expect(school.reload).to be_persisted
      end
    end
  end
end
