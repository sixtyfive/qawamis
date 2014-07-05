require 'test_helper'

class ArabicRootsControllerTest < ActionController::TestCase
  setup do
    @arabic_root = arabic_roots(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:arabic_roots)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create arabic_root" do
    assert_difference('ArabicRoot.count') do
      post :create, arabic_root: { book_id: @arabic_root.book_id, name: @arabic_root.name, start_page: @arabic_root.start_page }
    end

    assert_redirected_to arabic_root_path(assigns(:arabic_root))
  end

  test "should show arabic_root" do
    get :show, id: @arabic_root
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @arabic_root
    assert_response :success
  end

  test "should update arabic_root" do
    patch :update, id: @arabic_root, arabic_root: { book_id: @arabic_root.book_id, name: @arabic_root.name, start_page: @arabic_root.start_page }
    assert_redirected_to arabic_root_path(assigns(:arabic_root))
  end

  test "should destroy arabic_root" do
    assert_difference('ArabicRoot.count', -1) do
      delete :destroy, id: @arabic_root
    end

    assert_redirected_to arabic_roots_path
  end
end
