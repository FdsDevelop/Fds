require "test_helper"

class FdsContextMenuControllerTest < ActionDispatch::IntegrationTest
  test "should get files_operation" do
    get fds_context_menu_files_operation_url
    assert_response :success
  end
end
