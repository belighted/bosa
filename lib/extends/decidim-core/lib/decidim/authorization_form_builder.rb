# frozen_string_literal: true

require "active_support/concern"

module AuthorizationFormBuilderExtend
  extend ActiveSupport::Concern

  included do

    def all_fields
      fields = []
      public_attributes.map do |name, type|
        template = @template.content_tag(:div, input_field(name, type), class: "field")
        if name.to_sym == :document_number
          help_text = I18n.t("decidim.authorization_form.document_number_help_text")
          template += content_tag(:p, help_text, class: "help-text") if help_text.present?
        end
        fields << template
      end

      safe_join(fields)
    end

  end
end

Decidim::AuthorizationFormBuilder.send(:include, AuthorizationFormBuilderExtend)
