class UploadFilesController < ApplicationController
  @@FILES_UPLOAD_STAT = {}

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

  def create_file
    # dump_params
    ret = {}

    opt_flag = params[:opt_flag].to_i
    dir_path = params[:dir_path].to_s
    file_md5 = params[:file_md5].to_s
    file_name = params[:file_name].to_s
    file_size = params[:file_size].to_i
    chip_count = params[:chip_count].to_i
    chip_index = params[:chip_index].to_i
    chip_size = params[:chip_size].to_i
    chip_md5 = params[:chip_md5].to_s
    chip_data = params[:chip_data]

    fds_storage_path = Rails.application.config.fds.storage_path
    aim_path = fds_storage_path + dir_path
    file_path = File.join(aim_path, file_name)
    temp_file_path = file_path + Rails.application.config.fds.temp_ext

    hash_key = "#{file_md5}_#{file_path}"


    begin
      if opt_flag == 0 # 创建文件请求
        FileUtils.mkdir_p(aim_path)
        FileUtils.rm_rf(temp_file_path) if File.exist?(temp_file_path)
        FileUtils.touch(temp_file_path)


        node_path_str = File.join(dir_path,file_name)
        if FdsNode.find_by_node_path_str(node_path_str)
          raise RuntimeError, "File existed"
        end

        time_out_ms = Rails.application.config.fds.upload_time_out_ms
        if @@FILES_UPLOAD_STAT[hash_key]
          @@FILES_UPLOAD_STAT[hash_key][:opt_flag] = 0
          @@FILES_UPLOAD_STAT[hash_key][:ret_code] = 0
          @@FILES_UPLOAD_STAT[hash_key][:data] = { file_name: file_name, file_md5: file_md5, cur_chip: 0 }
          if @@FILES_UPLOAD_STAT[hash_key][:fds_timer].nil? || !@@FILES_UPLOAD_STAT[hash_key][:fds_timer].instance_of?(FdsTimer)
            temp_fds_timer = FdsTimer.new(time_out_ms) do ||
              FileUtils.rm_rf(temp_file_path) if File.exist?(temp_file_path)
            end
            @@FILES_UPLOAD_STAT[hash_key][:fds_timer] = temp_fds_timer
          end

        else
          @@FILES_UPLOAD_STAT[hash_key] = { opt_flag: 0, ret_code: 0, data: { file_name: file_name, file_md5: file_md5, cur_chip: 0 }}
          temp_fds_timer = FdsTimer.new(time_out_ms) do ||
            FileUtils.rm_rf(temp_file_path) if File.exist?(temp_file_path)
          end
          @@FILES_UPLOAD_STAT[hash_key][:fds_timer] = temp_fds_timer
        end

        @@FILES_UPLOAD_STAT[hash_key][:fds_timer].reset # 重置定时器


        ret[:ret_code] = 0
        ret[:err_msg] = ""
        ret[:data] = ""
      elsif opt_flag == 1 # 存入切片请求
        unless @@FILES_UPLOAD_STAT[hash_key]
          raise RuntimeError, "upload task not existed"
        end
        @@FILES_UPLOAD_STAT[hash_key][:fds_timer].reset # 重置定时器
        cur_chip = @@FILES_UPLOAD_STAT[hash_key][:data][:cur_chip]
        if chip_index != cur_chip
          raise RuntimeError, "chip index error"
        end
        File.open(temp_file_path, 'ab') do |file|
          file.write(chip_data.read)
        end
        @@FILES_UPLOAD_STAT[hash_key][:data][:cur_chip] = cur_chip+1
        ret[:ret_code] = 0
        ret[:err_msg] = ""
        ret[:data] = ""
      elsif opt_flag == 2 # 处理文件请求
        unless @@FILES_UPLOAD_STAT[hash_key]
          raise RuntimeError, "upload task not existed"
        end
        @@FILES_UPLOAD_STAT[hash_key][:fds_timer].reset # 重置定时器
        cur_chip = @@FILES_UPLOAD_STAT[hash_key][:data][:cur_chip]
        if cur_chip != chip_count
          raise RuntimeError, "chip index error"
        end
        temp_file_md5 = Digest::MD5.hexdigest(File.read(temp_file_path))
        if temp_file_md5.to_s.upcase != file_md5.upcase
          raise RuntimeError, "Integrity verification failed"
        end
        FileUtils.mv(temp_file_path, file_path)
        @@FILES_UPLOAD_STAT[hash_key][:fds_timer].cancel_timer_task # 重置定时器
        @@FILES_UPLOAD_STAT.delete(hash_key)

        dir_node = FdsNode.find_by_node_path_str!(dir_path)
        new_node = FdsNode.new(parent_node: dir_node, node_type: FdsNode.FILE_TYPE, name: file_name, size: file_size, md5: file_md5)
        new_node.save!

        ret[:ret_code] = 0
        ret[:err_msg] = ""
        ret[:data] = ""
      else
        ret[:ret_code] = -1
        ret[:err_msg] = "unknown operation"
        ret[:data] = ""
      end
    rescue RuntimeError,ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      @@FILES_UPLOAD_STAT.delete(hash_key)
      ret[:ret_code] = -1
      ret[:err_msg] = e.message
      ret[:data] = ""
    end

    puts "result = #{ret}"
    render json: ret
  end

end
