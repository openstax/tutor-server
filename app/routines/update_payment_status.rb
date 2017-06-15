class UpdatePaymentStatus
  lev_routine express_output: :response

  def exec(uuid:)
    status.set_job_args(uuid: uuid)

    purchased_item = PurchasedItem.find(uuid: uuid)
    return if purchased_item.nil?

    outputs.response = OpenStax::Payments::Api.check_payment(product_instance_uuid: uuid)

    save_response_to_purchased_item(outputs.response, purchased_item)
  end

  def save_response_to_purchased_item(response, purchased_item)
    if purchased_item.is_a?(CourseMembership::Models::Student)
      purchased_item.is_paid = response[:paid]
      purchased_item.first_paid_at ||= response[:changed_at]
      purchased_item.save! if purchased_item.changed?
    end
  end

end
