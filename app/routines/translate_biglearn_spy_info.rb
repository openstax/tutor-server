class TranslateBiglearnSpyInfo

  lev_routine

  protected

  def exec(spy_info:)
    outputs.spy_info = {}

    return if spy_info.nil?

    stringified_spy_info = spy_info.deep_stringify_keys

    outputs.spy_info = stringified_spy_info.except('assignment_history')

    return unless stringified_spy_info.has_key?('assignment_history')

    history = stringified_spy_info.fetch('assignment_history')

    task_uuids = history.values.map { |hash| hash['assignment_uuid'] }.compact

    task_id_by_uuid = Tasks::Models::Task.where(uuid: task_uuids).pluck(:uuid, :id).to_h

    outputs.spy_info['task_history'] = {}

    history.each do |key, value|
      outputs.spy_info['task_history'][key] =
        if value.has_key?('assignment_uuid')
          assignment_uuid = value['assignment_uuid']

          value.except('assignment_uuid').merge(
            'task_id' => task_id_by_uuid[assignment_uuid],
            'task_uuid' => assignment_uuid
          )
        else
          value
        end
    end
  end
end
