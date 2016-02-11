module Admin
  class ResearchDataController < BaseController

    def index
    end

    def create
      filename = "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
      ExportAndUploadResearchData.perform_later(filename)
      redirect_to admin_research_data_path,
                  notice: "#{ExportAndUploadResearchData::RESEARCH_FOLDER}/#{filename} should be available in a few minutes in ownCloud (does not refresh automatically)"
    end

  end
end
