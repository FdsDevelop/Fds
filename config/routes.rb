Rails.application.routes.draw do
  get 'fdss_api_keys/index'
  get 'fds_context_menu/files_operation'
  get 'home/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "rails/health#show", as: :rails_health_check

  post "upload_file", to: "upload_files#create_file"

  get "file_explore", to: "file_manager#file_explore", as: "file_explore"
  post "create_dir", to: "file_manager#create_dir", as: "create_dir"
  post "delete_nodes", to: "file_manager#delete_nodes", as: "delete_nodes"
  post "move_nodes", to: "file_manager#move_nodes", as: "move_nodes"
  post "copy_nodes", to: "file_manager#copy_nodes", as: "copy_nodes"
  post "re_name", to: "file_manager#re_name", as: "re_name"
  get "direct_download", to: "file_manager#direct_download", as: "direct_download"
  post "get_detail", to:"file_manager#get_detail", as: "get_detail"

  post "select_target_dir", to: "file_manager#select_target_dir", as: "dir_node_info"

  # Fdss API
  post "get_all_node_ids", to: "fdss_sync_manager#all_node_ids_without_root", as: "get_all_node_ids"
  post "get_nodes_info", to: "fdss_sync_manager#get_nodes_info_by_ids", as: "get_nodes_info"
  post "get_root_info", to: "fdss_sync_manager#get_root_info", as: "get_root_info"
  get "fdss_download", to: "fdss_sync_manager#fdss_download", as: "fdss_download"


  # Defines the root path route ("/")
  root "home#index"

  # devise_for :users

  Rails.application.routes.draw do
  get 'fdss_api_keys/index'
    devise_for :users, controllers: {
      registrations: 'users/registrations'
    }
  end

  get "system_settings", to:"settings#system_settings", as: "system_settings"
  get "user_settings", to:"settings#user_settings", as:"user_settings"

  post "fdss_api_key_create", to: "fdss_api_keys#create", as: "fdss_api_key_create"
  post "fdss_api_key_destroy", to: "fdss_api_keys#destroy", as: "fdss_api_key_destroy"
  get "fdss_api_key_detail", to: "fdss_api_keys#detail", as: "fdss_api_key_detail"
end
