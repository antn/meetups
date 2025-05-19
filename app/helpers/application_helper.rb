# frozen_string_literal: true

module ApplicationHelper
  def page_info(info = {})
    @page_title = info[:title] if info[:title]
  end

  def page_title
    if @page_title
      "#{@page_title} · OffKai Expo Meetups"
    else
      "OffKai Expo Meetups"
    end
  end
end
