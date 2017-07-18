class UpdatePaymentStatus
  lev_routine express_output: :response

  def exec(uuid:, fail_if_not_found: true)
    status.set_job_args(purchased_item_uuid: uuid)

    purchased_item = PurchasedItem.find(uuid: uuid)
    return if purchased_item.nil?

    begin
      outputs.response = OpenStax::Payments::Api.check_payment(product_instance_uuid: uuid)
    rescue OpenStax::Payments::RemoteError => err
      return if err.status == 404 && !fail_if_not_found
      raise err
    end

    log(:info) { "Got payment status for #{uuid}: #{outputs.response.to_h}" }

    # TODO fail if response not 2xx and write spec showing job retried

    case purchased_item
    when CourseMembership::Models::Student
      save_response_to_student(outputs.response, purchased_item)
    end
  end

  def save_response_to_student(response, student)
    student.is_paid = response[:paid]

    if student.changes['is_paid'] = [true, false]
      student.is_refund_pending = false
    end

    student.first_paid_at ||= Chronic.parse(response[:purchased_at])
    student.save! if student.changed?
  end

  def log(level, &block)
    Rails.logger.tagged(self.class.name) { |logger| logger.public_send(level, &block) }
  end
end
