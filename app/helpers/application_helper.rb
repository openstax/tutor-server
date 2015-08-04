module ApplicationHelper
  def bootstrap_flash
    HashWithIndifferentAccess.new({ success: 'alert-success',
                                    error: 'alert-error',
                                    alert: 'alert-block',
                                    notice: 'alert-info' })
  end

  def tf_to_yn(bool)
    bool ? "Yes" : "No"
  end
end
