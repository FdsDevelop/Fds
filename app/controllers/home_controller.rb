class HomeController < ApplicationController
  def index
    redirect_to file_explore_path(dir: "/")
  end
end
