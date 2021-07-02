# frozen_string_literal: true

module Decidim
  # This class deals with uploading the organization's logo.
  class AreaLogoUploader < ImageUploader
    process quality: Decidim.image_uploader_quality

    def extension_allowlist
      %w(png)
    end

     def content_type_allowlist
      %w(image/png)
    end

    version :medium do
      process resize_to_fit: [400, 160]
    end
  end
end
