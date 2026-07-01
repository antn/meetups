# frozen_string_literal: true

# Cloudflare R2 (our production Active Storage backend) doesn't implement the
# newer AWS SDK flexible-checksum headers, which the SDK now sends by default and
# R2 rejects. Fall back to only checksumming when a request actually requires it.
if ENV["R2_ENDPOINT"].present?
  require "aws-sdk-s3"

  Aws.config.update(
    request_checksum_calculation: "when_required",
    response_checksum_validation: "when_required"
  )
end
