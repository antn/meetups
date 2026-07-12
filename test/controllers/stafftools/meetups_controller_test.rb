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

    test "unapprove moves an approved meetup back to pending and clears review metadata" do
      meetup = meetups(:approved_cosplay)
      meetup.approve!(by: users(:admin))
      assert_not_nil meetup.reload.reviewed_at
      patch unapprove_stafftools_meetup_path(meetup)
      assert_redirected_to stafftools_meetups_path
      meetup.reload
      assert_predicate meetup, :pending?
      assert_nil meetup.reviewed_by_id
      assert_nil meetup.reviewed_at
    end

    test "cancel unpublishes an approved meetup and emails the host and attendees" do
      meetup = meetups(:approved_cosplay)
      # Hosted by member with admin RSVP'd, so both should be notified.
      assert_enqueued_emails 2 do
        patch cancel_stafftools_meetup_path(meetup)
      end
      assert_redirected_to stafftools_meetups_path
      assert_predicate meetup.reload, :cancelled?
    end

    test "merge moves RSVPs to the target and cancels the source" do
      source = meetups(:approved_karaoke) # attendee: guest
      target = meetups(:approved_cosplay) # attendee: admin

      patch merge_stafftools_meetup_path(source), params: { target_id: target.id }

      assert_redirected_to stafftools_meetup_path(target)
      source.reload
      assert_predicate source, :cancelled?
      assert_equal target.id, source.merged_into_id
      assert_equal [ users(:admin), users(:guest) ].map(&:id).sort, target.attendances.pluck(:user_id).sort
    end

    test "merge without a target redirects back with an alert" do
      source = meetups(:approved_karaoke)

      patch merge_stafftools_meetup_path(source)

      assert_redirected_to stafftools_meetup_path(source)
      assert_equal "Choose a meetup to merge into.", flash[:alert]
      assert_predicate source.reload, :approved?
      assert_equal 1, source.attendances.count
    end

    test "merge responds with JSON" do
      source = meetups(:approved_karaoke)
      target = meetups(:approved_cosplay)

      patch merge_stafftools_meetup_path(source), params: { target_id: target.id }, as: :json
      assert_response :success
      body = response.parsed_body
      assert body["ok"]
      assert_includes body["notice"], source.title

      patch merge_stafftools_meetup_path(target), params: { target_id: source.id }, as: :json
      assert_response :unprocessable_entity
      assert_not response.parsed_body["ok"]
    end

    test "show offers a merge target picker for a live meetup" do
      get stafftools_meetup_path(meetups(:approved_karaoke))
      assert_response :success
      assert_match "Merge into another meetup", response.body
      assert_select "select[name='target_id'] option", text: /Cosplay Contest/
    end

    test "unapprove emails the host that the meetup is back to pending" do
      meetup = meetups(:approved_cosplay)
      assert_enqueued_email_with MeetupsMailer, :meetup_reverted, args: [ { meetup: meetup } ] do
        patch unapprove_stafftools_meetup_path(meetup)
      end
    end

    test "reject can be applied to an already approved meetup" do
      meetup = meetups(:approved_cosplay)
      patch reject_stafftools_meetup_path(meetup), params: { rejection_reason: "Venue conflict" }
      assert_redirected_to stafftools_meetups_path
      meetup.reload
      assert_predicate meetup, :rejected?
      assert_equal "Venue conflict", meetup.rejection_reason
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
