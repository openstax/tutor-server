class UpdatePaymentStatus
  lev_routine express_output: :response

  def exec(uuid:)
    status.set_job_args(purchased_item_uuid: uuid)

    purchased_item = PurchasedItem.find(uuid: uuid)
    return if purchased_item.nil?

    outputs.response = OpenStax::Payments::Api.check_payment(product_instance_uuid: uuid)

    # TODO fail if response not 2xx and write spec showing job retried
    # log either way

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

    student.first_paid_at ||= response[:changed_at]
    student.save! if student.changed?
  end
end
