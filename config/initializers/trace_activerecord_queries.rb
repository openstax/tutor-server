ActiveRecordQueryTrace.enabled = true if Rails.env.development? && EnvUtilities.load_boolean(
  name: 'TRACE_ACTIVERECORD_QUERIES', default: false
)
