require "test_helper"

class ApisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api = apis(:one)
  end

  test "should get index" do
    get apis_url, as: :json
    assert_response :success
  end

  test "should create api" do
    assert_difference("Api.count") do
      post apis_url, params: { api: { name: @api.name } }, as: :json
    end

    assert_response :created
  end

  test "should show api" do
    get api_url(@api), as: :json
    assert_response :success
  end

  test "should update api" do
    patch api_url(@api), params: { api: { name: @api.name } }, as: :json
    assert_response :success
  end

  test "should destroy api" do
    assert_difference("Api.count", -1) do
      delete api_url(@api), as: :json
    end

    assert_response :no_content
  end
end
