# frozen_string_literal: true

require "active_support/concern"

module InitiativeSerializerExtend
  extend ActiveSupport::Concern

  included do
    include Decidim::ApplicationHelper
    include Decidim::ResourceHelper
    include Decidim::TranslationsHelper

    # Public: Initializes the serializer with an initiative.
    def initialize(initiative)
      @initiative = initiative
    end

    # Public: Exports a hash with the serialized data for this initiative.
    def serialize
      {
        id: initiative.id,
        reference: initiative.reference,
        title: initiative.title,
        description: initiative.description,
        state: initiative.state,
        created_at: initiative.created_at,
        published_at: initiative.published_at,
        signature_end_date: initiative.signature_end_date,
        signature_type: initiative.signature_type,
        scope: {
          id: initiative.scope.try(:id),
          name: initiative.scope.try(:name) || empty_translatable
        },
        type: {
          id: initiative.type.try(:id),
          name: initiative.type.try(:title) || empty_translatable
        },
        authors: {
          id: initiative.author_users.map(&:id),
          name: initiative.author_users.map(&:name)
        },
        hashtag: initiative.hashtag,
        signature_start_date: initiative.signature_start_date,
        offline_votes: initiative.offline_votes,
        answer: initiative.answer,
        attachments: {
          attachment_collections: serialize_attachment_collections,
          files: serialize_attachments
        },
        components: serialize_components,
        firms: {
          scopes: uniq_vote_scopes
        }
      }
    end

    private

    attr_reader :initiative

    def serialize_attachment_collections
      return unless initiative.attachment_collections.any?

      initiative.attachment_collections.map do |collection|
        {
          id: collection.try(:id),
          name: collection.try(:name),
          weight: collection.try(:weight),
          description: collection.try(:description)
        }
      end
    end

    def serialize_attachments
      return unless initiative.attachments.any?

      initiative.attachments.map do |attachment|
        {
          id: attachment.try(:id),
          title: attachment.try(:title),
          weight: attachment.try(:weight),
          description: attachment.try(:description),
          attachment_collection: {
            name: attachment.attachment_collection.try(:name),
            weight: attachment.attachment_collection.try(:weight),
            description: attachment.attachment_collection.try(:description)
          },
          remote_file_url: Decidim::AttachmentPresenter.new(attachment).attachment_file_url
        }
      end
    end

    def serialize_components
      serializer = Decidim::Exporters::ParticipatorySpaceComponentsSerializer.new(@initiative)
      serializer.serialize
    end

    def uniq_vote_scopes
      return 0 if initiative.votes.blank?

      initiative_votes_scopes = []
      initiative.votes.map(&:decrypted_metadata).each do |metadata|
        next if metadata.blank?
        next unless metadata.is_a? Hash

        initiative_votes_scopes << metadata[:user_scope_id]
      end

      initiative_votes_scopes.uniq.size
    end
  end
end

Decidim::Initiatives::InitiativeSerializer.send(:include, InitiativeSerializerExtend)
