# frozen_string_literal: true

class MeetupsMailer < ApplicationMailer
  def meetup_requested(meetup:)
    @meetup = meetup
    @user = meetup.user

    mail(
      to: @user.email,
      subject: "OffKai Expo meetup request received: #{@meetup.name}",
    )
  end

  def meetup_approved(meetup:)
    @meetup = meetup
    @user = meetup.user

    mail(
      to: @user.email,
      subject: "OffKai Expo meetup approved: #{@meetup.name}",
    )
  end

  def meetup_rejected(meetup:)
    @meetup = meetup
    @user = meetup.user

    mail(
      to: @user.email,
      subject: "OffKai Expo meetup rejected: #{@meetup.name}",
    )
  end
end
