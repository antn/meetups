# frozen_string_literal: true

class MeetupsMailer < ApplicationMailer
  def meetup_requested(meetup:)
    @meetup = meetup
    @user = meetup.user

    mail(
      to: @user.email,
      subject: "OffKai Expo meetup request received: #{@meetup.title}",
    )
  end

  def meetup_approved(meetup:)
    @meetup = meetup
    @user = meetup.user

    mail(
      to: @user.email,
      subject: "OffKai Expo meetup approved: #{@meetup.title}",
    )
  end

  def meetup_rejected(meetup:)
    @meetup = meetup
    @user = meetup.user

    mail(
      to: @user.email,
      subject: "OffKai Expo meetup rejected: #{@meetup.title}",
    )
  end
end
