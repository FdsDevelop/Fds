class FdssSyncManagerController < ApplicationController
  skip_before_action :verify_authenticity_token

  def dump_params
    puts "======================================"
    if params.present?
      puts "get source params = #{params}"
      params.each_key do |key|
        puts "get params #{key} = #{params[key]}"
      end
    end
    puts "======================================"
  end

  before_action :dump_params

  def fdss_status_report
    ret = {}
    ret[:ret_code] = 0
    ret[:err_msg] = ""
    ret[:data] = {}

    begin
      data = JSON.parse(params[:data])
      fdss_serial = data["fdss_serial"]
      fdss_status = data["fdss_status"]


    rescue => e
      ret[:ret_code] = -2
      ret[:err_msg] = e.message
      ret[:data] = {}
    end


    render json: ret
  end

  def all_node_ids_without_root
    ret = {}
    ret[:ret_code] = 0
    ret[:err_msg] = ""
    ret[:data] = {}
    
    root_node = FdsNode.root
    node_ids = FdsNode.where.not(id:root_node.id).pluck(:id)
    ret[:data][:all_node_ids] = node_ids

    render json: ret
  end

  def get_nodes_info_by_ids
    max_count = 30

    ret = {}
    ret[:ret_code] = 0
    ret[:err_msg] = ""
    ret[:data] = {}

    begin
    data = JSON.parse(params[:data])
    ids = data["node_ids"]

    if ids.length > max_count
      ret[:ret_code] = -1
      ret[:err_msg] = "max ids count is #{max_count}"
      ret[:data] = {}
    else
      nodes = FdsNode.where(id:ids)
      ret[:data][:nodes] = {}
      nodes.each do |node|
        ret[:data][:nodes][node.id] = {id: node.id, name: node.name, parent_node_id: node.parent_node_id, node_type: node.node_type, md5:node.md5, size:node.size, path: node.node_path_str}
      end
    end
    rescue => e
      ret[:ret_code] = -2
      ret[:err_msg] = e.message
      ret[:data] = {}
    end


    render json: ret

  end

  def get_root_info
    ret = {}
    ret[:ret_code] = 0
    ret[:err_msg] = ""
    ret[:data] = {}

    begin
      root_node = FdsNode.root
      ret[:data][:root] = {id: root_node.id, name: root_node.name, parent_node_id: root_node.parent_node_id, node_type: root_node.node_type, md5:root_node.md5, size:root_node.size, path: root_node.node_path_str}
    rescue => e
      ret[:ret_code] = -2
      ret[:err_msg] = e.message
      ret[:data] = {}
    end


    render json: ret
  end

  def fdss_download
    id = params[:id]
    fds_storage_path = Rails.application.config.fds.storage_path
    begin
      node = FdsNode.find(id)
      node_path = File.join(fds_storage_path, node.node_path_str)
      send_file node_path, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    rescue => e
      render plain: "#{e.message}", status: :error
    end
  end


end
