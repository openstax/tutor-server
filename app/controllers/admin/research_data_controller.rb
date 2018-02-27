module Admin
  class ResearchDataController < BaseController

    def index
    end

    def create
      task_types_params = params.fetch(:export_research_data, {})
                                .fetch(:task_types, [])
                                .reject(&:blank?)

      if task_types_params.blank?
        redirect_to admin_research_data_path, alert: "You must select either Tutor or Concept Coach"
        return
      end

      current_time = Time.current
      filename = "export_#{current_time.strftime("%Y%m%dT%H%M%SZ")}.csv"
      concept_coach_values = [ Tasks::Models::Task.task_types[:concept_coach] ]
      mapping = {
        "tutor" => Tasks::Models::Task.task_types.values - concept_coach_values,
        "concept_coach" => concept_coach_values
      }

      task_types = task_types_params.flat_map do |task_types_param|
        mapping.fetch(task_types_param) do |key|
          redirect_to admin_research_data_path, alert: "Invalid aplication: #{key}"
          return
        end
      end

      from_date = params[:export_research_data][:from] || Time.at(0).to_s
      to_date = params[:export_research_data][:to] || current_time.to_s
      ExportAndUploadResearchData.perform_later(
        filename: filename, from: from_date, to: to_date, task_types: task_types
      )
      redirect_to admin_research_data_path,
                  notice: "#{filename} is being created and will be uploaded to Box when ready"
    end

  end
end
