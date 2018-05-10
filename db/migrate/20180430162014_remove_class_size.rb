class RemoveClassSize < ActiveRecord::Migration
  def up
    Salesforce::Models::AttachedRecord
      .where(salesforce_class_name: 'OpenStax::Salesforce::Remote::ClassSize')
      .delete_all
  end

  def down
  end
end
