class ApplicationController < ActionController::Base
  def only_lan_host_allow
    if original_host != Rails.application.config.fds.lan_host_ip
      render plain: 'Forbidden', status: :forbidden
    end
  end

  def original_host
    forwarded_host = request.headers['X-Forwarded-Host']
    if forwarded_host.present?
      forwarded_host.split(',').map(&:strip).first
    else
      request.host
    end
  end

end
