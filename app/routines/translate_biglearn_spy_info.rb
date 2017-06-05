class TranslateBiglearnSpyInfo

  lev_routine

  protected

  def exec(spy_info:)
    task_uuids = spy_info.values.map { |hash| hash[:assignment_uuid] }

    task_id_by_uuid = Tasks::Models::Task.where(uuid: task_uuids).pluck(:uuid, :id).to_h

    translated_spy_info = {}
    spy_info.each do |key, value|
      translated_spy_info[key] = value.merge(task_id: task_id_by_uuid[value.assignment_uuid])
    end

    outputs.spy_info = translated_spy_info
  end
end
