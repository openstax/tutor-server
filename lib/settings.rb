module Settings
  def self.feature_flags
      {
        is_payments_enabled: Payments.payments_enabled,
        teacher_student_enabled: Db[:teacher_student_enabled],
        force_browser_reload: Db[:force_browser_reload],
        pulse_insights: Db[:pulse_insights]
      }
  end
end

Dir[File.join(__dir__, 'settings', '*.rb')].each{ |file| require file }
