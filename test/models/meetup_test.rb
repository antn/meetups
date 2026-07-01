# frozen_string_literal: true

require "test_helper"

class MeetupTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def build_meetup(description:)
    day = scheduling_days(:friday)
    Meetup.new(
      event: events(:expo),
      user: users(:member),
      location: locations(:main_stage),
      scheduling_day: day,
      starts_at: day.valid_start_times.find { |t| t.hour == 13 },
      title: "Sample",
      description: description,
      tags: [ tags(:gaming) ]
    )
  end

  test "description is required" do
    meetup = build_meetup(description: "")
    assert_not meetup.valid?
    assert_includes meetup.errors[:description], "can't be blank"
  end

  test "description must be at least 15 characters" do
    assert_not build_meetup(description: "a" * 14).valid?
    assert build_meetup(description: "a" * 15).valid?
  end

  test "description must be at most 280 characters" do
    assert_not build_meetup(description: "a" * 281).valid?
    assert build_meetup(description: "a" * 280).valid?
  end

  test "tagged_with returns meetups carrying any of the given tags" do
    cosplay = Meetup.tagged_with([ tags(:cosplay).public_id ])
    assert_includes cosplay, meetups(:approved_cosplay)

    gaming = Meetup.tagged_with([ tags(:gaming).public_id ])
    assert_not_includes gaming, meetups(:approved_cosplay)
  end

  test "can't claim a timeslot that has already passed" do
    past_day = events(:expo).scheduling_days.create!(date: Date.current - 1, start_time: "10:00", end_time: "17:00")
    meetup = Meetup.new(
      event: events(:expo), user: users(:member), location: locations(:main_stage),
      scheduling_day: past_day, starts_at: past_day.valid_start_times.first,
      title: "Old news", description: "A meetup whose time has passed.", tags: [ tags(:gaming) ]
    )
    assert_not meetup.valid?
    assert_includes meetup.errors[:starts_at], "has already passed"
  end

  test "editable_by? allows the owner and admins while live" do
    meetup = meetups(:pending_vtuber) # owned by member, pending
    assert meetup.editable_by?(users(:member))
    assert meetup.editable_by?(users(:admin))
    assert_not meetup.editable_by?(nil)

    stranger = User.create!(uid: 9100, login: "nope", email: "n@example.com")
    assert_not meetup.editable_by?(stranger)
  end

  test "editable_by? is false once rejected or cancelled" do
    meetup = meetups(:pending_vtuber)
    meetup.reject!(by: users(:admin), reason: "no")
    assert_not meetup.editable_by?(users(:member))
    assert_not meetup.editable_by?(users(:admin))
  end

  test "due_for_reminder covers approved meetups starting within the lead window" do
    approved = meetups(:approved_cosplay)
    approved.update_column(:starts_at, 30.minutes.from_now)

    assert_includes Meetup.due_for_reminder, approved
  end

  test "due_for_reminder excludes pending, already-reminded, started, and far-off meetups" do
    pending = meetups(:pending_vtuber)
    pending.update_column(:starts_at, 30.minutes.from_now)
    assert_not_includes Meetup.due_for_reminder, pending, "pending meetups are never reminded"

    approved = meetups(:approved_cosplay)

    approved.update_columns(starts_at: 30.minutes.from_now, reminder_sent_at: Time.current)
    assert_not_includes Meetup.due_for_reminder, approved, "already reminded"

    approved.update_columns(starts_at: 5.minutes.ago, reminder_sent_at: nil)
    assert_not_includes Meetup.due_for_reminder, approved, "already started"

    approved.update_column(:starts_at, 3.hours.from_now)
    assert_not_includes Meetup.due_for_reminder, approved, "outside the lead window"
  end

  test "reminder_recipients is the host plus attendees, deduped" do
    meetup = meetups(:approved_cosplay) # host: member, attendee: admin
    recipients = meetup.reminder_recipients
    assert_equal [ users(:admin), users(:member) ].map(&:id).sort, recipients.map(&:id).sort

    # Host who has also RSVP'd appears only once.
    meetup.attendances.create!(user: meetup.user)
    assert_equal meetup.reminder_recipients.map(&:id), meetup.reminder_recipients.map(&:id).uniq
  end

  test "deliver_start_reminder! sends once and is idempotent across sweeps" do
    meetup = meetups(:approved_cosplay) # 2 recipients: member (host) + admin

    assert_enqueued_emails 2 do
      assert meetup.deliver_start_reminder!
    end
    assert_not_nil meetup.reload.reminder_sent_at

    assert_no_enqueued_emails do
      assert_not meetup.deliver_start_reminder!
    end
  end

  test "rescheduling an approved meetup re-arms an already-sent reminder" do
    meetup = meetups(:approved_cosplay)
    meetup.update_column(:reminder_sent_at, Time.current)

    day = meetup.scheduling_day
    meetup.update!(starts_at: day.valid_start_times.find { |t| t.hour == 12 })

    assert_nil meetup.reload.reminder_sent_at
  end
end
