ActiveRecordQueryTrace.enabled = true if EnvUtilities.load_boolean(
  name: 'TRACE_ACTIVERECORD_QUERIES', default: false
)
