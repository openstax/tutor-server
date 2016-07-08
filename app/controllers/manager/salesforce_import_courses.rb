module Manager::SalesforceImportCourses

  def import_courses
    outputs = ImportSalesforceCourses.call(
      include_real_salesforce_data: params[:use_real_data]
    )

    flash[:notice] = "Of #{outputs.num_failures + outputs.num_successes} candidate records in Salesforce, " +
      "#{outputs.num_successes} were successfully imported and #{outputs.num_failures} failed."

    redirect_to salesforce_path
  end

end
