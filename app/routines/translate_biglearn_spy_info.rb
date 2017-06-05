class TranslateBiglearnSpyInfo

  lev_routine

  protected

  def exec(spy_info:)
    task_uuids = spy_info.values.map { |hash| hash['assignment_uuid'] }.compact

    task_id_by_uuid = Tasks::Models::Task.where(uuid: task_uuids).pluck(:uuid, :id).to_h

    translated_spy_info = {}
    spy_info.each do |key, value|
      assignment_uuid = value['assignment_uuid']

      translated_spy_info[key] = assignment_uuid.nil? ? value : value.except('assignment_uuid')
                                                                     .merge(
        'task_id' => task_id_by_uuid[assignment_uuid],
        'task_uuid' => assignment_uuid
      )
    end

    outputs.spy_info = translated_spy_info
  end
end
