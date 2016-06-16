class UpdateSalesforceStats

  lev_routine transaction: :no_transaction

  def exec
    log { "Starting." }

    attached_records = Salesforce::AttachedRecord.preload(:salesforce_objects)

    num_records = attached_records.length
    num_errors = 0
    num_updates = 0

    attached_records.group_by{ |ar| ar.salesforce_class_name }
                    .each do |klass_name, attached_records|
      case klass_name
      when 'Salesforce::Remote::ClassSize', 'Salesforce::Remote::OsAncillary'
        # We assume all attached_to's are Entity::Course's here
        course_ids = attached_records.map{ |ar| ar.tutor_gid.try(:model_id) }.compact
        course_id_to_preloaded_course_map = \
          Entity::Course.where(id: course_ids)
                        .preload([:teachers, {periods: :latest_enrollments}])
                        .index_by(&:id)

        attached_records.each do |attached_record|
          begin
            record = attached_record.record
            course_id = Integer(attached_record.tutor_gid.model_id)
            course = course_id_to_preloaded_course_map[course_id]

            # TODO count archived periods
            periods = course.periods

            class_size.num_teachers = course.teachers.length
            class_size.num_students = course.periods.flat_map(&:latest_enrollments).length
            class_size.num_sections = course.periods.length
          rescue Exception => e
            num_errors += 1
            record.error = "Unable to update stats: #{e.message}" if record.present?
            OpenStax::RescueFrom.perform_rescue(e)
          end

          begin
            if record.present? && record.changed?
              record.save
              num_updates += 1
            end
          rescue Exception => e
            num_errors += 1
            OpenStax::RescueFrom.perform_rescue(e)
          end
        end
      end
    end

    log {
      "Ran for #{num_records} record(s); Made #{num_updates} " +
      "update(s); #{num_errors} error(s) occurred."
    }

    outputs[:num_records] = num_records
    outputs[:num_errors] = num_errors
    outputs[:num_updates] = num_updates
  end

  def log(&block)
    Rails.logger.info { "[UpdateSalesforceStats] #{block.call}" }
  end

end
