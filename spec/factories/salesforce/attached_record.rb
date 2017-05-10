FactoryGirl.define do
  factory :salesforce_attached_record, class: 'Salesforce::Models::AttachedRecord' do
    transient do
      tutor_object      { FactoryGirl.create :course_profile_course }
      salesforce_object { OpenStax::Salesforce::Remote::OsAncillary.new(id: "foo") }
    end

    tutor_gid { (tutor_object).to_global_id.to_s }
    salesforce_class_name { salesforce_object.class.name }
    salesforce_id { salesforce_object.id }

    after(:build) do |object, evaluator|
      object.salesforce_object = evaluator.salesforce_object
    end
  end
end
