require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fds
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.time_zone = 'Beijing'
    config.fds = ActiveSupport::OrderedOptions.new
  end
end

Rails.application.configure do
  config.fds.storage_path = Rails.root.join("files").to_s
  config.fds.temp_ext = ".fds.save_tmp"
  config.fds.upload_time_out_ms = 60000
  config.fds.wan_address = ENV.fetch("FDS_WAN_ADDRESS") { "http://example.com:3000" }
  config.fds.lan_address = ENV.fetch("FDS_LAN_ADDRESS") { "http://localhost:3000" }
  config.fds.web_port = ENV.fetch("PORT") { 3000 }
  config.fds.lan_host_ip = Rails.application.config.fds.lan_address.sub("http://","").sub("https://","").chomp("/").chomp(":#{Rails.application.config.fds.web_port}")
end
