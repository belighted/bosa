# frozen_string_literal: true

require "active_support/concern"

module CreateInitiativeControllerExtend
  extend ActiveSupport::Concern

  # Changes moved from decidim-module-initiatives_nosignature_allowed

  included do

    def show
      enforce_permission_to :create, :initiative
      send("#{step}_step", initiative: session_initiative, type_id: params[:type_id])
    end

    def user_has_no_permission
      flash[:alert] = t("actions.unauthorized", scope: "decidim.core")
      # redirect_to(request.referer || user_has_no_permission_path)
      redirect_to(user_has_no_permission_path)
    end

    private

    def previous_form_step(parameters)
      @form = build_form(Decidim::Initiatives::PreviousForm, parameters)

      if !single_initiative_type? && initiative_type_id.blank?
        redirect_to create_initiative_path(:select_initiative_type)
        return
      end

      render_wizard
    end

    def fill_data_step(parameters)
      @form = build_form(Decidim::Initiatives::InitiativeForm, parameters)
      @form.attachment = form(Decidim::AttachmentForm).from_params({title: parameters.dig(:initiative, :attachment, :title)})

      render_wizard
    end

  end
end

Decidim::Initiatives::CreateInitiativeController.send(:include, CreateInitiativeControllerExtend)
