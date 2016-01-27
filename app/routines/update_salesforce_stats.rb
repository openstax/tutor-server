class UpdateSalesforceStats

  lev_routine transaction: :no_transaction

  def exec
    log { "Starting." }

    attached_records = Salesforce::AttachedRecord.preload

    num_records = attached_records.count
    num_errors = 0
    num_updates = 0

    attached_records.group_by{ |ar| ar.record.class }.each do |klass, attached_records|
      case klass
      when Salesforce::Remote::ClassSize
        course_id_to_attached_record_map = attached_records.group_by{ |ar| ar.attached_to.id }
        course_ids = course_id_to_attached_record_map.keys

        Entity::Course.where(id: course_ids)
                      .preload([:teachers, {periods: :active_enrollments}])
                      .find_each do |course|
          begin
            record = course_id_to_attached_record_map[course.id].record
            update_class_size_stats(record, course)
          rescue Exception => e
            num_errors += 1
            record.error = "Unable to update stats: #{e.message}" if record.present?
            OpenStax::RescueFrom.perform_rescue(e)
          end

          begin
            if record.present?
              if record.changed?
                record.save
                num_updates += 1
              end
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

  def update_class_size_stats(attached_records)
    course_id_to_attached_record_map = attached_records.group_by{ |ar| ar.attached_to.id }
    course_ids = course_id_to_attached_record_map.keys
    Entity::Course.where(id: course_ids)
                  .preload([:teachers, {periods: :active_enrollments}])
                  .find_each do |course|
      class_size = course_id_to_attached_record_map[course.id].record
      update_class_size_stats(class_size, course)
    end
  end

  def update_class_size_stats(class_size, course)
    class_size.num_teachers = course.teachers.length
    class_size.num_students = course.periods.flat_map(&:active_enrollments).length
    class_size.num_sections = course.periods.length
  end

  def log(&block)
    Rails.logger.info { "[UpdateSalesforceStats] #{block.call}" }
  end

end
