module ApplicationHelper
  def bootstrap_flash
    HashWithIndifferentAccess.new({ success: 'alert-success',
                                    error: 'alert-error',
                                    alert: 'alert-block',
                                    notice: 'alert-info' })
  end
end
