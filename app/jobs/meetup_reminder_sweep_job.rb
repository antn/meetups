# frozen_string_literal: true

# Runs on a schedule (see config/recurring.yml). Finds approved meetups that
# are about to start and sends their "starting soon" reminders. Evaluating
# eligibility at send time — rather than pre-scheduling a per-meetup job — means
# rescheduled, cancelled, rejected, or newly-approved meetups are handled for
# free: only meetups that are approved and due right now get reminded.
class MeetupReminderSweepJob < ApplicationJob
  queue_as :default

  def perform
    Meetup.due_for_reminder.find_each(&:deliver_start_reminder!)
  end
end
