module ApplicationHelper
  def render_flash_messages
    flash_messages = flash.map do |key, message|
      if key == "notice"
        content_tag(:div, message, class: "alert alert-success", role: "alert")
      elsif key == "alert"
        content_tag(:div, message, class: "alert alert-warning", role: "alert")
      else
        content_tag(:div, message, class: "alert alert-#{key}", role: "alert")
      end
    end
    safe_join(flash_messages)
  end

  def need_admin?
    if User.where(admin: true).count == 0
      true
    else
      false
    end
  end

  def is_admin?
    current_user.admin?
  end

end
