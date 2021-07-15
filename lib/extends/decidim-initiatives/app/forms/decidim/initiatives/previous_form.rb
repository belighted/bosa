# frozen_string_literal: true

require "active_support/concern"

module InitiativesPreviousFormExtend
  extend ActiveSupport::Concern

  included do
    translatable_attribute :title, String
    translatable_attribute :description, String

    clear_validators!
    validates :title, :description, translatable_presence: true
    validates :description, length: { maximum: 4000 }
    validates :type_id, presence: true
  end
end

Decidim::Initiatives::PreviousForm.send(:include, InitiativesPreviousFormExtend)
