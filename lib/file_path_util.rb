module FilePathUtil
  def path_str_2_path_list(path_str)
    if path_str.nil? || !path_str.instance_of?(String)
      return []
    end
    path_list = path_str.strip.split("/").reject!(&:empty?)
  end

  def path_list_2_path_str(path_list)
    if path_list.nil? || !path_list.is_a?(Array)
      return ""
    end
    path_str = ""
    path_list.each { |path| path_str = "#{path_str}/#{path}" }
    path_str
  end
end