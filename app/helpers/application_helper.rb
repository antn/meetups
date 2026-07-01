module ApplicationHelper
  SITE_NAME = "OffKai Expo Meetups".freeze
  DEFAULT_META_DESCRIPTION = "Discover and schedule fan meetups at OffKai Expo.".freeze

  # Full <title> for the page, with a site-name fallback.
  def page_title
    content_for(:title).presence || SITE_NAME
  end

  # Plain title for social cards (strips the " · OffKai Expo" suffix if present).
  def social_title
    page_title.split(" · ").first
  end

  def meta_description
    content_for(:meta_description).presence || DEFAULT_META_DESCRIPTION
  end

  # Absolute URL to the social share image. Override per-page with
  # `content_for :social_image, "https://..."`.
  def social_image_url
    content_for(:social_image).presence || "#{request.base_url}/og-image.png"
  end
end
