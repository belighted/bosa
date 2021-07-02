# frozen_string_literal: true

require "active_support/concern"

module CommentsHelperExtend
  extend ActiveSupport::Concern

  included do
    delegate :current_locale, to: :controller

    def translatable?
      @organization ||= try(:current_organization)
      @organization ||= try(:current_participatory_space).try(:organization)
      @organization ||= try(:current_component).try(:organization)
      @organization ||= request.env["decidim.current_organization"]
      @organization.try(:deepl_api_key).present? && @organization.try(:translatable_locales).count > 1
    end
  end
end

Decidim::Comments::CommentsHelper.send(:include, CommentsHelperExtend)
Decidim::Comments::CommentCell.send(:include, Decidim::Comments::CommentsHelper)
Decidim::Comments::CommentCell.send(:include, Decidim::DeeplHelper)
