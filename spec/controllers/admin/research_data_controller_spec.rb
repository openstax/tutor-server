require 'rails_helper'

RSpec.describe Admin::ResearchDataController, type: :controller do
  let(:admin) { FactoryGirl.create(:user, :administrator) }

  before { controller.sign_in(admin) }

  context 'GET #index' do
    it 'responds with success' do
      get :index

      expect(response).to be_ok
    end
  end

  context 'POST #create' do
    it 'calls ExportAndUploadResearchData and redirects to #index' do
      expect(ExportAndUploadResearchData).to receive(:perform_later)
      post :create, export_research_data: { task_types: ["tutor"] }
      expect(response).to redirect_to admin_research_data_path
    end

    context "assigns default dates" do
      let(:task_types) do
        Tasks::Models::Task.task_types.values - [ Tasks::Models::Task.task_types[:concept_coach] ]
      end

      specify "with invalid 'from' and 'to' parameters" do
        right_now = Time.current
        Timecop.freeze(right_now) do
          filename = "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
          expect(ExportAndUploadResearchData).to receive(:perform_later).with(
            filename: filename, from: Time.at(0).to_s, to: right_now.to_s, task_types: task_types
          )

          post :create, from: "not-even", to: "valid", export_research_data: {task_types: ["tutor"]}
        end
      end

      specify "with blank 'from' and 'to' parameters" do
        right_now = Time.current
        Timecop.freeze(right_now) do
          filename = "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
          expect(ExportAndUploadResearchData).to receive(:perform_later).with(
            filename: filename, from: Time.at(0).to_s, to: right_now.to_s, task_types: task_types
          )

          post :create, from: "", to: "", export_research_data: {task_types: ["tutor"]}
        end
      end
    end

    it "raises an exception when export_research_data is missing" do
      allow(ExportAndUploadResearchData).to receive(:perform_later)
      expect{post :create}.to raise_error StandardError
    end

    it "raises an exception when export_research_data does not contain task_types" do
      allow(ExportAndUploadResearchData).to receive(:perform_later)
      expect{post :create, export_research_data: {}}.to raise_error StandardError
    end

    it "raises an exception with invalid task_types parameters" do
      allow(ExportAndUploadResearchData).to receive(:perform_later)

      expect{post :create, from: Date.yesterday.to_s, to: Date.today.to_s,
                    export_research_data: {task_types: ["whatev"]}
            }.to raise_error StandardError
    end
  end
end
