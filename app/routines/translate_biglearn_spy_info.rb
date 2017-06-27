class TranslateBiglearnSpyInfo

  lev_routine transaction: :no_transaction

  protected

  def exec(spy_info:)
    outputs.spy_info = {}

    return if spy_info.nil?

    stringified_spy_info = spy_info.deep_stringify_keys

    outputs.spy_info = stringified_spy_info.except('assignment_history')

    return unless stringified_spy_info.has_key?('assignment_history')

    history = stringified_spy_info.fetch('assignment_history')

    all_task_uuids = history.values.map { |hash| hash['assignment_uuid'] }.compact
    all_book_container_uuids = history.values
                                      .flat_map { |hash| hash['book_container_uuids'] }
                                      .compact

    task_id_by_uuid = Tasks::Models::Task.where(uuid: all_task_uuids).pluck(:uuid, :id).to_h
    cnx_page_uuid_by_book_container_uuid = Content::Models::Page
      .where(tutor_uuid: all_book_container_uuids)
      .pluck(:tutor_uuid, :uuid)
      .to_h

    outputs.spy_info['task_history'] = {}

    history.each do |key, value|
      outputs.spy_info['task_history'][key] =
        if value.has_key?('assignment_uuid')
          assignment_uuid = value['assignment_uuid']
          book_container_uuids = value['book_container_uuids']

          value.except('assignment_uuid', 'book_container_uuids').merge(
            'task_id' => task_id_by_uuid[assignment_uuid],
            'task_uuid' => assignment_uuid,
            'cnx_page_uuids' => book_container_uuids.map do |book_container_uuid|
              cnx_page_uuid_by_book_container_uuid[book_container_uuid]
            end.compact,
            'book_container_uuids' => book_container_uuids
          )
        else
          value
        end
    end
  end
end
