module Admin
  class ResearchDataController < BaseController

    def index
    end

    def create
      filename = "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
      mapping = {
        "tutor" => Tasks::Models::Task.task_types.values_at(:homework, :reading, :chapter_practice,
                   :page_practice, :mixed_practice, :external, :event, :extra),
        "concept_coach" => Tasks::Models::Task.task_types.values_at(:concept_coach)
      }

      task_types_params = params.fetch(:export_research_data).fetch(:task_types).reject{|i|i.blank?}

      if task_types_params.blank?
        flash.now[:alert] = "You must select at least one type of Tasks"
        render :index
        return
      end

      task_types = task_types_params.inject([]){ |result, task_types_param|
        result.concat(mapping.fetch(task_types_param){|key| raise "Don't know about application #{key}"})
      }

      from_date = params[:export_research_data][:from] || "1/1/1970"
      to_date = params[:export_research_data][:to] || Time.current.to_s
      ExportAndUploadResearchData.perform_later(filename: filename, from: from_date, to: to_date, task_types: task_types)
      redirect_to admin_research_data_path,
                  notice: "#{ExportAndUploadResearchData::RESEARCH_FOLDER}/#{filename} should be available in a few minutes in ownCloud (does not refresh automatically)"
    end

  end
end
