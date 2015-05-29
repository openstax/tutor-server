if (
     Rails.env.development? &&
     EnvUtilities.load_boolean(name: 'TRACE_ACTIVERECORD_QUERIES', default: false)
    )

  ActiveRecordQueryTrace.enabled = true
  puts "ActiveRecord Query Trace is enabled! This will be way too slow!"
end


