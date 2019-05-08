module ApplicationHelper
  def bootstrap_flash
    HashWithIndifferentAccess.new({ success: 'alert-success',
                                    error: 'alert-danger',
                                    alert: 'alert-warning',
                                    notice: 'alert-info' })
  end

  def tf_to_yn(bool)
    bool ? "Yes" : "No"
  end

  def is_real_production_site?
    request.host == 'tutor.openstax.org'
  end
end
