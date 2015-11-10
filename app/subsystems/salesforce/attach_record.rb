module Salesforce
  class AttachRecord
    lev_routine express_output: :attached_record

    def exec(record:, to:)
      model = Models::AttachedRecord.create(
        tutor_gid: to.to_global_id.to_s,
        salesforce_class_name: record.class.name,
        salesforce_id: record.id
      )
      transfer_errors_from(model, {type: :verbatim}, true)
      outputs.attached_record = AttachedRecord.new(strategy: model)
    end
  end
end
