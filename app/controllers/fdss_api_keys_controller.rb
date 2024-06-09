class FdssApiKeysController < ApplicationController

  def create
    begin
      FdssApiKey.generate_new_api_key
      flash[:success] = "执行成功"
    rescue => e
      flash[:danger] = e.message
    end
    redirect_to request.referrer
  end

  def destroy
    begin
      id = params[:id].to_i
      fdss_api_key = FdssApiKey.find(id)
      fdss_api_key.destroy!
      flash[:success] = "执行成功"
    rescue => e
      flash[:danger] = e.message
    end
    redirect_to request.referrer
  end

  def detail
    begin
      id = params[:id].to_i
      @fdss_api_key = FdssApiKey.find(id)
    rescue => e
      @fdss_api_key = nil
    end
    render layout: false
  end


end
