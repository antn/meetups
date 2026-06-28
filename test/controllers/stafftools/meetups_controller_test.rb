# frozen_string_literal: true

require "test_helper"

module Stafftools
  class MeetupsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in users(:admin) }

    test "index defaults to pending meetups" do
      get stafftools_meetups_path
      assert_response :success
      assert_match "VTuber Fan Meetup", response.body
    end

    test "index can filter to a status with no meetups" do
      get stafftools_meetups_path(status: "cancelled")
      assert_response :success
      assert_no_match "VTuber Fan Meetup", response.body
      assert_match "No cancelled meetups", response.body
    end

    test "approving moves a meetup into the approved filter" do
      meetups(:pending_vtuber).approve!(by: users(:admin))
      get stafftools_meetups_path(status: "approved")
      assert_response :success
      assert_match "VTuber Fan Meetup", response.body
    end

    test "index ignores an unknown status and falls back to pending" do
      get stafftools_meetups_path(status: "bogus")
      assert_response :success
      assert_match "VTuber Fan Meetup", response.body
    end

    test "a rejected meetup shows under the rejected filter with its reason" do
      meetups(:pending_vtuber).reject!(by: users(:admin), reason: "Off-topic")
      get stafftools_meetups_path(status: "rejected")
      assert_response :success
      assert_match "VTuber Fan Meetup", response.body
      assert_match "Off-topic", response.body
    end

    test "show renders the meetup" do
      get stafftools_meetup_path(meetups(:pending_vtuber))
      assert_response :success
      assert_match "VTuber Fan Meetup", response.body
    end

    test "edit renders the form" do
      get edit_stafftools_meetup_path(meetups(:pending_vtuber))
      assert_response :success
      assert_match "Edit meetup", response.body
    end

    test "admin updates a meetup" do
      patch stafftools_meetup_path(meetups(:pending_vtuber)), params: { meetup: {
        title: "Edited by staff",
        description: meetups(:pending_vtuber).description,
        location_id: meetups(:pending_vtuber).location_id,
        slot: "#{scheduling_days(:friday).id}:#{meetups(:pending_vtuber).starts_at.to_i}",
        tag_ids: [ tags(:gaming).id ]
      } }
      assert_redirected_to stafftools_meetup_path(meetups(:pending_vtuber))
      assert_equal "Edited by staff", meetups(:pending_vtuber).reload.title
    end

    test "invalid update re-renders with errors" do
      patch stafftools_meetup_path(meetups(:pending_vtuber)), params: { meetup: {
        title: "Edited",
        description: "short",
        location_id: meetups(:pending_vtuber).location_id,
        slot: "#{scheduling_days(:friday).id}:#{meetups(:pending_vtuber).starts_at.to_i}",
        tag_ids: [ tags(:gaming).id ]
      } }
      assert_response :unprocessable_entity
      assert_equal "VTuber Fan Meetup", meetups(:pending_vtuber).reload.title
    end

    test "approve publishes the meetup" do
      meetup = meetups(:pending_vtuber)
      patch approve_stafftools_meetup_path(meetup)
      assert_redirected_to stafftools_meetups_path
      meetup.reload
      assert_predicate meetup, :approved?
      assert_equal users(:admin).id, meetup.reviewed_by_id
      assert_not_nil meetup.reviewed_at
    end

    test "reject requires a reason" do
      meetup = meetups(:pending_vtuber)
      patch reject_stafftools_meetup_path(meetup), params: { rejection_reason: "  " }
      assert_redirected_to stafftools_meetups_path
      follow_redirect!
      assert_match "reason is required", response.body
      assert_predicate meetup.reload, :pending?
    end

    test "reject with a reason records it" do
      meetup = meetups(:pending_vtuber)
      patch reject_stafftools_meetup_path(meetup), params: { rejection_reason: "Off-topic" }
      assert_redirected_to stafftools_meetups_path
      meetup.reload
      assert_predicate meetup, :rejected?
      assert_equal "Off-topic", meetup.rejection_reason
      assert_equal users(:admin).id, meetup.reviewed_by_id
    end

    test "approved meetups drop off the default pending list" do
      meetups(:pending_vtuber).approve!(by: users(:admin))
      get stafftools_meetups_path
      assert_response :success
      assert_no_match "VTuber Fan Meetup", response.body
      assert_match "No pending meetups", response.body
    end
  end
end
