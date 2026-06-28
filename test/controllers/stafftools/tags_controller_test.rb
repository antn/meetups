# frozen_string_literal: true

require "test_helper"

module Stafftools
  class TagsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in users(:admin) }

    test "index lists tags" do
      get stafftools_tags_path
      assert_response :success
      assert_match "Cosplay", response.body
    end

    test "creates a tag with a color" do
      assert_difference -> { Tag.count }, 1 do
        post stafftools_tags_path, params: { tag: { name: "Music", color: "orange" } }
      end
      assert_redirected_to stafftools_tags_path
      created = Tag.order(:created_at).last
      assert_equal events(:expo).id, created.event_id
      assert_equal "orange", created.color
    end

    test "rejects an unknown color" do
      assert_no_difference -> { Tag.count } do
        post stafftools_tags_path, params: { tag: { name: "Music", color: "chartreuse" } }
      end
      assert_response :unprocessable_entity
    end

    test "updates a tag color" do
      patch stafftools_tag_path(tags(:gaming)), params: { tag: { name: "Gaming", color: "yellow" } }
      assert_redirected_to stafftools_tags_path
      assert_equal "yellow", tags(:gaming).reload.color
    end

    test "rejects a duplicate name" do
      assert_no_difference -> { Tag.count } do
        post stafftools_tags_path, params: { tag: { name: "cosplay" } }
      end
      assert_response :unprocessable_entity
    end

    test "updates a tag" do
      patch stafftools_tag_path(tags(:gaming)), params: { tag: { name: "Video Games" } }
      assert_redirected_to stafftools_tags_path
      assert_equal "Video Games", tags(:gaming).reload.name
    end

    test "destroys a tag" do
      assert_difference -> { Tag.count }, -1 do
        delete stafftools_tag_path(tags(:gaming))
      end
      assert_redirected_to stafftools_tags_path
    end
  end
end
