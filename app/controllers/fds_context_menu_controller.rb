class FdsContextMenuController < ApplicationController
  layout false
  def files_operation
    @nodes = FdsNode.where(id: params[:ids])
  end
end
