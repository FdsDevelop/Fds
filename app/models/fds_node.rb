class FdsNode < ApplicationRecord

  def self.DIR_TYPE
    1
  end

  def self.FILE_TYPE
    0
  end

  def self.copy_sub_nodes(source_node, target_node)
    source_node.sub_nodes.each do |sub_node|
      new_sub_node = FdsNode.new(sub_node.attributes.except("id", "created_at", "updated_at", "parent_node_id"))
      target_node.sub_nodes << new_sub_node
      FdsNode.copy_sub_nodes(sub_node,new_sub_node)
    end
  end

  def self.copy_node(source_node, target_node)
    if target_node.node_path.include?(source_node)
      raise "目标目录是源目录的子目录"
    end
    new_source_node = FdsNode.new(source_node.attributes.except("id", "created_at", "updated_at", "parent_node_id"))
    target_node.sub_nodes << new_source_node
    FdsNode.copy_sub_nodes(source_node, new_source_node)
    new_source_node.save!
  end



  def self.root
    FdsNode.find_by(parent_node_id: nil, name: "root", node_type: FdsNode.DIR_TYPE)
  end

  def self.find_by_node_path_str(node_path_str)
    if node_path_str.nil? || !node_path_str.instance_of?(String)
      return nil
    end
    if node_path_str == "/" || node_path_str == ""
      return FdsNode.root
    end
    if node_path_str.include?("/")
      node_names = node_path_str.strip.split("/").select{|node_name| node_name && node_name != "" }
    else
      node_names = [node_path_str]
    end

    # puts "node names = #{node_names}"

    return nil unless node_names.present?

    current_node = FdsNode.root
    node_names.each do |node_name|
      # puts "node name = #{node_name}, sub_nodes_names = #{current_node.sub_nodes_names}"
      current_node = current_node.sub_nodes.detect { |node| node.name == node_name }
      unless current_node
        current_node = nil
        break
      end
    end
    current_node
  end

  def self.find_by_node_path_str!(node_path_str)
    node = FdsNode.find_by_node_path_str(node_path_str)
    unless node
      raise ActiveRecord::RecordNotFound, "FdsNode not existed"
    end
    node
  end

  belongs_to :parent_node, class_name: "FdsNode", foreign_key: "parent_node_id" unless self == FdsNode.root
  has_many :sub_nodes, class_name: "FdsNode", foreign_key: "parent_node_id"

  def node_path
    node_path = []
    cur_node = self
    while cur_node.parent_node
      node_path.unshift(cur_node)
      cur_node = cur_node.parent_node
    end
    node_path.unshift(cur_node)
    node_path
  end

  def node_path_str
    node_path_str = ""
    node_path.each { |node| node_path_str = "#{node_path_str}/#{node.name}" }
    node_path_str.sub!(/^\/root/, "")
  end

  def sub_nodes_names
    sub_nodes_names = []
    self.sub_nodes.each { |node| sub_nodes_names.push(node.name) }
    sub_nodes_names
  end

  def node_type_str
    if self.node_type == FdsNode.DIR_TYPE
      return "dir"
    else
      file_ext_name = File.extname(self.name).downcase

      if [".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp", ".svg", ".gif"].include?(file_ext_name)
        return "img"
      elsif [".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".aiff", ".m4a"].include?(file_ext_name)
        return "audio"
      elsif [".doc", ".docx"].include?(file_ext_name)
        return "doc"
      elsif [".xls", ".xlsx"].include?(file_ext_name)
        return "excel"
      elsif [".img", ".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".tar.gz", ".tar.bz2", ".tar.xz"].include?(file_ext_name)
        return "pack"
      elsif [".pdf"].include?(file_ext_name)
        return "pdf"
      elsif [".ppt", ".pptx"].include?(file_ext_name)
        return "ppt"
      elsif [".txt"].include?(file_ext_name)
        return "txt"
      elsif [".mp4", ".mov", ".avi", ".mkv", ".wmv", ".flv", ".webm", ".m4v", ".3gp", ".mpeg", ".mpg"].include?(file_ext_name)
        return "video"
      else
        return "unknown"
      end

    end
  end

  def totle_size
    t_size = 0

    if node_type == FdsNode.DIR_TYPE
      sub_nodes.each do |node|
        t_size = t_size + node.totle_size
      end
    elsif node_type == FdsNode.FILE_TYPE
      if size.nil?
        t_size = 0
      else
        t_size = size
      end
    end
    t_size
  end

  def human_size
    ActiveSupport::NumberHelper.number_to_human_size(totle_size)
  end

  def human_updated_at
    updated_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  # def human_updated_at
  #   time_difference = Time.now - self.updated_at
  #   seconds_in_a_day = 24 * 60 * 60
  #   days_difference = (time_difference / seconds_in_a_day).to_i
  #
  #   if days_difference >= 1
  #     "#{days_difference} day#{days_difference > 1 ? 's' : ''} ago"
  #   else
  #     time_ago = distance_of_time_in_words(self.updated_at, Time.now)
  #     "#{time_ago} ago"
  #   end
  # end

  def human_created_at
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  validates :node_type, presence: { message: "类型未指定" }
  validates :node_type, inclusion: { in: [FdsNode.FILE_TYPE, FdsNode.DIR_TYPE], message: "类型错误" }
  validates :name, presence: { message: "名称不能为空" }

  validate :not_allow_loopback
  validate :parent_node_must_be_dir

  # 更新时间戳
  before_update :update_updated_at

  # 创建目录
  # 创建文件 和 复制文件/目录
  before_create :create_name_uniqueness
  # 移动文件/目录
  before_update :update_name_uniqueness
  # 删除文件/目录
  before_destroy :destroy_sub_nodes

  private

  def update_updated_at
    self.updated_at = Time.current
  end

  def destroy_sub_nodes
    if self == FdsNode.root
      raise "不允许删除根目录"
    end
    self.sub_nodes.destroy_all
  end

  def sub_nodes_name_uniqueness
    same_dir_node_names = parent_node.sub_nodes_names
    puts "same dir names =#{same_dir_node_names}, self name = #{self.name}"
    errors.add(:sub_nodes, "文件名重复") if same_dir_node_names.include?(self.name)
  end

  def create_name_uniqueness
    same_dir_node_names = parent_node.sub_nodes_names
    puts "same dir names =#{same_dir_node_names}, self name = #{self.name}"
    if same_dir_node_names.include?(self.name)
      raise "文件名称重复"
    end
  end

  def update_name_uniqueness
    if changes.keys.include?("parent_node_id") || changes.keys.include?("name") # 只有修改 parent_node_id 和 name 的时候需要校验文件名称重复问题
      same_dir_node_names = parent_node.sub_nodes_names
      puts "same dir names =#{same_dir_node_names}, self name = #{self.name}"
      if same_dir_node_names.include?(self.name)
        raise "文件名称重复"
      end
    end

  end

  def parent_node_must_be_dir
    unless self == FdsNode.root
      errors.add(:parent_node, "父目录不能为空") if parent_node.nil?
      errors.add(:parent_node, "父目录必须是目录") if parent_node.node_type != FdsNode.DIR_TYPE
    end
  end

  def not_allow_loopback
    errors.add(:loopback, "不允许形成回环") unless (node_path.to_a.map(&:id) & sub_nodes.to_a.map(&:id)).empty?
  end

end
