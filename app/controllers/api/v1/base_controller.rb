# frozen_string_literal: true

module Api
  module V1
    class BaseController < Api::BaseController
      # V1 specific configurations
      before_action :set_api_version_v1

      protected

      def set_api_version_v1
        @api_version = 'v1'
      end

      # V1 specific helper methods can be added here
      def v1_feature_enabled?(feature)
        # Check if specific V1 features are enabled
        Rails.application.config.api_v1_features&.include?(feature.to_s)
      end

      private

      # V1 specific validations
      def valid_api_version?(version)
        version == 'v1'
      end
    end
  end
end