class InitiateRefund
  lev_routine

  def exec(uuid:)
    status.set_job_args(purchased_item_uuid: uuid)

    purchased_item = PurchasedItem.find(uuid: uuid)
    return if purchased_item.nil?

    response = OpenStax::Payments::Api.initiate_refund(product_instance_uuid: uuid)

    # TODO fail if response not 2xx and write spec showing job retried
    # log either way

    case purchased_item
    when CourseMembership::Models::Student
      purchased_item.update_attributes(is_refund_pending: true)
    end
  end

end
