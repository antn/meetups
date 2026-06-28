# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "OffKai Expo Meetups <noreply@meetups.offkaiexpo.com>"
  layout "mailer"
end
