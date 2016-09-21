module Admin
  class ResearchDataController < BaseController

    def index
    end

    def create
      filename = "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
      from_date = Chronic.parse(params[:from])
      to_date = Chronic.parse(params[:to])
      date_range = from_date..to_date if from_date && to_date
      ExportAndUploadResearchData.perform_later(filename: filename, date_range: date_range, include_tutor: params[:tutor], include_concept_coach: params[:concept_coach])
      redirect_to admin_research_data_path,
                  notice: "#{ExportAndUploadResearchData::RESEARCH_FOLDER}/#{filename} should be available in a few minutes in ownCloud (does not refresh automatically)"
    end

  end
end
