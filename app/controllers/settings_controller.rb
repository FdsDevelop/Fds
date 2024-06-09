class SettingsController < ApplicationController

  def system_settings
    @tabs = {system_config: "系统配置", api_manager: "API访问", user_manager: "用户管理"}
    @path_method = "system_settings_path"
    @fdss_api_keys = FdssApiKey.all
  end

  def user_settings

  end
end
