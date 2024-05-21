module UploadFilesHelper

  def render_upload_file(dir_path)
    dir_paths = []
    if dir_path && dir_path.instance_of?(String) && dir_path != ""
      unless dir_path.start_with?("/")
        dir_path = "/"+dir_path
      end
      dir_paths = dir_path.split("/").reject(&:empty?)
    else
      dir_path = "/"
    end
    render "layouts/upload_file", locals:{dir_path: dir_paths, dir_path_str: dir_path}
  end
end
