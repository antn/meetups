# frozen_string_literal: true

require "test_helper"

class MeetupsMailerTest < ActionMailer::TestCase
  test "meetup_reminder addresses the recipient and names the meetup" do
    meetup = meetups(:approved_cosplay)

    host_mail = MeetupsMailer.meetup_reminder(meetup: meetup, user: meetup.user)
    assert_equal [ meetup.user.email ], host_mail.to
    assert_match "Starting soon", host_mail.subject
    assert_match meetup.title, host_mail.subject
    assert_match meetup.location.name, host_mail.body.to_s
    assert_match "Your meetup is starting", host_mail.body.to_s

    attendee = users(:admin)
    attendee_mail = MeetupsMailer.meetup_reminder(meetup: meetup, user: attendee)
    assert_equal [ attendee.email ], attendee_mail.to
    assert_match "you RSVP'd to is starting", attendee_mail.body.to_s
  end
end
