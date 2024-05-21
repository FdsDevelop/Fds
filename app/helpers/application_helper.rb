module ApplicationHelper
  def render_flash_messages
    flash_messages = flash.map do |key, message|
      content_tag(:div, message, class: "alert alert-#{key}", role: "alert")
    end
    safe_join(flash_messages)
  end

end
