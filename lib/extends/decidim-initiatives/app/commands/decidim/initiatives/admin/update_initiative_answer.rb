# frozen_string_literal: true

require "active_support/concern"

module UpdateInitiativeAnswerExtend
  extend ActiveSupport::Concern

  included do
    private

    def attributes
      attrs = {
        answer: form.answer,
        answer_url: form.answer_url,
        state: form.state,
        answer_date: answer_date
      }

      attrs[:answered_at] = Time.current if form.answer.present?

      if form.signature_dates_required?
        attrs[:signature_start_date] = form.signature_start_date
        attrs[:signature_end_date] = form.signature_end_date

        if initiative.published? && form.signature_end_date != initiative.signature_end_date &&
          form.signature_end_date > initiative.signature_end_date
          @notify_extended = true
        end
      end

      attrs
    end

    def answer_date
      return nil unless form.answer_date_allowed?

      form.answer_date
    end
  end
end

Decidim::Initiatives::Admin::UpdateInitiativeAnswer.send(:include, UpdateInitiativeAnswerExtend)
