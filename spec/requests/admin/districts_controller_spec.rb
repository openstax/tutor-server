require 'rails_helper'

RSpec.describe Admin::DistrictsController, type: :request do
  let(:admin)    { FactoryBot.create(:user_profile, :administrator) }
  let(:district) { FactoryBot.build :school_district_district, name: 'Hello World' }

  before { sign_in! admin }

  context 'GET #index' do
    before { district.save! }

    it 'assigns @districts and @page_header' do
      get admin_districts_url

      expect(assigns[:districts].count).to eq(1)
      expect(assigns[:districts].first.name).to eq('Hello World')
      expect(assigns[:page_header]).to eq("Manage districts")
    end
  end

  context 'GET #new' do
    it 'assigns @district and @page_header' do
      get new_admin_district_url

      expect(assigns[:district]).to be_present
      expect(assigns[:page_header]).to eq("Create a district")
    end
  end

  context 'POST #create' do
    context 'unused name' do
      it 'creates the district and redirects to #index' do
        expect { post admin_districts_url, params: { district: { name: 'Hello World' } } }.to(
          change { SchoolDistrict::Models::District.count }.by(1)
        )

        expect(response).to redirect_to(admin_districts_url)

        district = SchoolDistrict::Models::District.order(:id).last
        expect(district.name).to eq 'Hello World'
      end
    end

    context 'used name' do
      before { district.save! }

      it 'displays an error message and assigns @district and @page_header' do
        expect { post admin_districts_url, params: { district: { name: 'Hello World' } } }.not_to(
          change { SchoolDistrict::Models::District.count }
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:error]).to include('Name has already been taken')
        expect(assigns[:district]).to be_present
        expect(assigns[:page_header]).to eq("Create a district")
      end
    end
  end

  context 'GET #edit' do
    before { district.save! }

    it 'assigns @district and @page_header' do
      get edit_admin_district_url(district.id)

      expect(assigns[:district]).to be_present
      expect(assigns[:page_header]).to eq("Edit district")
    end
  end

  context 'PATCH #update' do
    before { district.save! }

    context 'unused name' do
      it 'updates the district and redirects to #index' do
        patch admin_district_url(district.id), params: { district: { name: 'Hello Again' } }

        expect(response).to redirect_to(admin_districts_url)
        expect(district.reload.name).to eq 'Hello Again'
      end
    end

    context 'used name' do
      before { FactoryBot.create :school_district_district, name: 'Hello Again' }

      it 'displays an error message and assigns @district and @page_header' do
        patch admin_district_url(district.id), params: { district: { name: 'Hello Again' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:error]).to include('Name has already been taken')
        expect(assigns[:district]).to be_present
        expect(assigns[:page_header]).to eq("Edit district")
        expect(district.reload.name).to eq 'Hello World'
      end
    end
  end

  context 'DELETE #destroy' do
    before { district.save! }

    context 'without schools' do
      it 'deletes the district and redirects to #index' do
        expect { delete admin_district_url(district.id) }.to(
          change { SchoolDistrict::Models::District.count }.by(-1)
        )

        expect(response).to redirect_to(admin_districts_url)
      end
    end

    context 'with schools' do
      before { FactoryBot.create :school_district_school, district: district }

      it 'redirects to #index and displays an error message' do
        expect { delete admin_district_url(district.id) }.not_to(
          change { SchoolDistrict::Models::District.count }
        )

        expect(response).to redirect_to(admin_districts_url)
        expect(flash[:error]).to include('Cannot delete a district that has schools.')
        expect(district.reload).to be_persisted
      end
    end
  end
end
