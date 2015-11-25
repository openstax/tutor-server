class UpdateSalesforceStats

  # not a routine!

  def self.call
    attached_records = Salesforce::AttachedRecord.all

    num_records = attached_records.count
    num_errors = 0
    num_updates = 0

    attached_records.each do |attached_record|
      begin
        record = attached_record.record
        attached_to = attached_record.attached_to

        case record
        when Salesforce::Remote::ClassSize
          update_class_size_stats(record, attached_to)
        end

      rescue Exception => e
        num_errors += 1
        record.error = "Unable to update stats #{e.message}"
        OpenStax::RescueFrom.perform_rescue(e)
      end

      begin
        num_updates += 1 if record.changed?
        record.save_if_changed
      rescue Exception => e
        num_errors += 1
        OpenStax::RescueFrom.perform_rescue(e)
      end
    end

    Rails.logger.info {
      "UpdateSalesforceStats ran for #{num_records} record(s); Made #{num_updates} update(s);#{num_errors} error(s) occurred."
    }

    {num_records: num_records, num_errors: num_errors, num_updates: num_updates}
  end

  def self.update_class_size_stats(class_size, course)
    class_size.num_teachers = CourseMembership::GetTeachers[course].count
    class_size.num_students = CourseMembership::GetCourseRoles[course: course, types: :student].count
    class_size.num_sections = CourseMembership::GetCoursePeriods[course: course].count
  end

end
