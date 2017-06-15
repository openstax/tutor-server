class PurchasedItem

  def self.exists?(uuid:)
    find(uuid: uuid).present?
  end

  def self.find(uuid:)
    CourseMembership::Models::Student.with_deleted.find_by(uuid: uuid) ||
    OpenStax::Payments::FakePurchasedItem.find(uuid)
  end

end
