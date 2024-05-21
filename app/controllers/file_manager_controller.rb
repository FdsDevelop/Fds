class FileManagerController < ApplicationController
  before_action :only_lan_host_allow, only: :direct_download

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

  def file_explore
    dir_path_str = params[:dir]
    @dir_node = FdsNode.find_by_node_path_str(dir_path_str)
    @dir_node = FdsNode.root unless @dir_node
  end

  def create_dir
    dir_path_str = params[:dir]
    dir_name = params[:dir_name]

    FdsNode.transaction do
      begin
        @dir_node = FdsNode.find_by_node_path_str!(dir_path_str)
        new_node = FdsNode.new(parent_node: @dir_node, node_type: FdsNode.DIR_TYPE, name: dir_name, size: 0)
        new_node.save!

        fds_storage_path = Rails.application.config.fds.storage_path
        aim_path = File.join(fds_storage_path, dir_path_str)
        aim_path = File.join(aim_path, dir_name)
        FileUtils.mkdir_p(aim_path)

        flash[:success] = "执行成功"
        redirect_to request.referrer
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, RuntimeError, Errno::ENAMETOOLONG, Errno::EACCES => e
        flash[:danger] = e.message
        redirect_to request.referrer
        raise ActiveRecord::Rollback
      end
    end
  end

  def delete_nodes
    ids = params[:ids]
    result = true
    nodes = FdsNode.where(id: ids)
    fds_storage_path = Rails.application.config.fds.storage_path
    nodes.each do |node|
      FdsNode.transaction do
        begin
          node_path = File.join(fds_storage_path, node.node_path_str)
          node.destroy!
          FileUtils.rm_rf(node_path) if File.exist?(node_path)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, RuntimeError, Errno::EISDIR, Errno::EACCES, Errno::ENOENT, Errno::EINVAL => e
          result = false
          puts "#{e.message}"
          raise ActiveRecord::Rollback
        end
      end
    end
    if result
      flash[:success] = "操作成功"
      redirect_to request.referrer
    else
      flash[:danger] = "操作失败"
      redirect_to request.referrer
    end
  end

  def select_target_dir
    ret = {}
    node_id = params[:target_node_id]
    node = FdsNode.find_by(id: node_id)
    if node && node.node_type == FdsNode.DIR_TYPE
      ret[:ret_code] = 0
      ret[:err_msg] = ""
      ret[:data] = {}
      ret[:data][:node] = { id: node.id, name: node.name, node_path_str: node.node_path_str, node_path: node.node_path.map { |node| { id: node.id, name: node.name } } }
      sub_dirs = node.sub_nodes.select { |node| node.node_type == FdsNode.DIR_TYPE }
      ret[:data][:sub_dir_nodes] = sub_dirs.map { |node| { id: node.id, name: node.name } }
    else
      ret[:ret_code] = -1
      ret[:err_msg] = "目录不存在"
      ret[:data] = {}
    end
    render json: ret
  end

  def move_nodes
    ids = JSON.parse(params[:ids])
    target_id = params[:target_id]

    result = true

    fds_storage_path = Rails.application.config.fds.storage_path

    begin
      target_node = FdsNode.find(target_id)
      target_path = File.join(fds_storage_path, target_node.node_path_str)
    rescue ActiveRecord::RecordNotFound => e
      flash[:danger] = "操作失败"
      redirect_to request.referrer
      return
    end

    nodes = FdsNode.where(id: ids)
    nodes.each do |node|
      FdsNode.transaction do
        begin
          node_path = File.join(fds_storage_path, node.node_path_str)
          node.update!(parent_node: target_node)
          FileUtils.mv(node_path, target_path)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, RuntimeError, Errno::EISDIR, Errno::EACCES, Errno::ENOENT, Errno::EEXIST, Errno::EINVAL => e
          result = false
          puts "#{e.message}"
          raise ActiveRecord::Rollback
        end
      end
    end

    if result
      flash[:success] = "操作成功"
      # redirect_to file_explore_path(dir: target_node.node_path_str)
      redirect_to request.referrer
    else
      flash[:danger] = "操作失败"
      redirect_to request.referrer
    end

  end

  def copy_nodes
    ids = params[:ids].map(&:to_i)
    target_id = params[:target_id].to_i
    ret = {}
    result = true

    fds_storage_path = Rails.application.config.fds.storage_path

    begin
      target_node = FdsNode.find(target_id)
      target_path = File.join(fds_storage_path, target_node.node_path_str)
    rescue ActiveRecord::RecordNotFound => e
      flash[:danger] = "操作失败"
      ret[:ret_code] = -1
      ret[:err_msg] = "操作失败"
      ret[:data] = {}
      render json: ret
      return
    end

    nodes = FdsNode.where(id: ids)
    nodes.each do |node|
      FdsNode.transaction do
        begin
          node_path = File.join(fds_storage_path, node.node_path_str)
          FdsNode.copy_node(node, target_node)
          FileUtils.cp_r(node_path, target_path)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, RuntimeError, Errno::EISDIR, Errno::EACCES, Errno::ENOENT, Errno::EEXIST, Errno::EINVAL => e
          result = false
          puts "#{e.message}"
          raise ActiveRecord::Rollback
        end
      end
    end

    if result
      flash[:success] = "操作成功"
      ret[:ret_code] = 0
      ret[:err_msg] = ""
      ret[:data] = {}
    else
      flash[:danger] = "操作失败"
      ret[:ret_code] = -1
      ret[:err_msg] = "操作失败"
      ret[:data] = {}
    end

    render json: ret
  end

  def re_name
    ids = JSON.parse(params[:ids])
    new_name = params[:new_name]

    fds_storage_path = Rails.application.config.fds.storage_path
    FdsNode.transaction do
      begin
        id = ids.first
        node = FdsNode.find(id)
        node_path = File.join(fds_storage_path, node.node_path_str)
        node.update!(name: new_name)

        new_node_path = File.join(fds_storage_path, node.node_path_str)
        File.rename(node_path, new_node_path)

        flash[:success] = "操作成功"
        redirect_to request.referrer
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, RuntimeError, Errno::EISDIR, Errno::EACCES, Errno::ENOENT, Errno::EEXIST, Errno::EINVAL, Errno::ENOTEMPTY => e
        flash[:danger] = "操作失败"
        puts "#{e.message}"
        redirect_to request.referrer
        raise ActiveRecord::Rollback
      end
    end
  end

  def direct_download
    id = params[:id]
    fds_storage_path = Rails.application.config.fds.storage_path
    begin
      node = FdsNode.find(id)
      node_path = File.join(fds_storage_path, node.node_path_str)
      send_file node_path, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    rescue  ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, RuntimeError, Errno::EISDIR, Errno::EACCES, Errno::ENOENT, Errno::EEXIST, Errno::EINVAL, Errno::ENOTEMPTY,ActionController::MissingFile => e
      flash[:danger] = "下载失败"
      redirect_to request.referrer
    end
  end

  def get_detail
    id = params[:id]
    wan_address = Rails.application.config.fds.wan_address
    ret = {}
    ret[:data] = []

    begin
      node = FdsNode.find(id)
      ret[:ret_code] = 0
      ret[:err_msg] = ""
      if node.node_type == FdsNode.FILE_TYPE
        ret[:data].push({"文件名": node.name})
        ret[:data].push({"大小": node.human_size})
        ret[:data].push({"创建日期": node.human_created_at})
        ret[:data].push({"修改日期": node.human_updated_at})
        ret[:data].push({"文件MD5": node.md5})
        if wan_address.end_with?("/")
          download_url = "#{wan_address}direct_download?id=#{node.id}"
        else
          download_url = "#{wan_address}/direct_download?id=#{node.id}"
        end
        ret[:data].push({"下载链接": download_url})
      else
        ret[:data].push({"目录名": node.name})
        ret[:data].push({"大小": node.human_size})
        ret[:data].push({"创建日期": node.human_created_at})
        ret[:data].push({"修改日期": node.human_updated_at})
      end
    rescue  ActiveRecord::RecordNotFound => e
      ret[:ret_code] = -1
      ret[:err_msg] = "文件或目录不存在!!!"
    end

    render json: ret
  end

end
