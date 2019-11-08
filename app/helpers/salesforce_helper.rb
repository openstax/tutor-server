module SalesforceHelper
  def salesforce_url
    Rails.application.secrets.salesforce[:instance_url]
  end

  def find_tutor_course_period_report_id
    Settings::Salesforce.find_tutor_course_period_report_id
  end

  def salesforce_find_tutor_course_period_link(param, value)
    if salesforce_url.blank?
      content_tag :i, 'SF instance_url not set'
    elsif find_tutor_course_period_report_id.blank?
      content_tag :i, 'SF Find Tutor Course Report ID not set'
    else
      link_to 'Show on SF',
              "#{salesforce_url}/#{find_tutor_course_period_report_id}?#{param}=#{value}",
              target: '_blank'
    end
  end

  def salesforce_course_link(course)
    salesforce_find_tutor_course_period_link(:pv0, course.uuid)
  end

  def salesforce_period_link(period)
    salesforce_find_tutor_course_period_link(:pv1, period.uuid)
  end
end
