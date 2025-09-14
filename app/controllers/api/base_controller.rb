# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    # Skip CSRF for API endpoints
    skip_before_action :verify_authenticity_token

    # API-specific error handling
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found_api
    rescue_from ActionController::ParameterMissing, with: :handle_missing_parameter
    rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized if defined?(Pundit)

    # Set JSON format as default
    before_action :set_default_format

    # API versioning
    before_action :check_api_version

    # Rate limiting (if implemented)
    # before_action :check_rate_limit

    protected

    # Set JSON as default format for API controllers
    def set_default_format
      request.format = :json unless params[:format]
    end

    # Check API version compatibility
    def check_api_version
      version = request.headers['Accept-Version'] || params[:version] || 'v1'

      unless valid_api_version?(version)
        render_error('Unsupported API version', :not_acceptable)
      end
    end

    # API response helpers (override parent methods for consistency)
    def render_success(data = nil, message = 'Success', status = :ok, meta = {})
      response_data = {
        success: true,
        message: message,
        data: data,
        meta: {
          timestamp: Time.current.iso8601,
          version: api_version
        }.merge(meta)
      }

      render json: response_data, status: status
    end

    def render_error(message = 'Error', status = :unprocessable_entity, errors = nil, meta = {})
      response_data = {
        success: false,
        message: message,
        errors: errors,
        meta: {
          timestamp: Time.current.iso8601,
          version: api_version
        }.merge(meta)
      }

      render json: response_data, status: status
    end

    # Paginated response helper
    def render_paginated_success(collection, serializer_class = nil, message = 'Success')
      serializer_class ||= "#{controller_name.classify}Serializer".constantize

      paginated_data = {
        items: serializer_class.new(collection.records, many: true).data,
        pagination: {
          current_page: collection.current_page,
          per_page: collection.limit_value,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          has_next_page: collection.next_page.present?,
          has_prev_page: collection.prev_page.present?
        }
      }

      render_success(paginated_data, message)
    end

    # Authentication helpers for API
    def authenticate_api_user!
      token = extract_token_from_header

      unless token && (@current_user = authenticate_with_token(token))
        render_error('Authentication required', :unauthorized)
      end
    end

    def current_api_user
      @current_user
    end

    # Authorization helper
    def authorize_resource!(resource = nil, action = nil)
      resource ||= controller_name.classify.constantize
      action ||= action_name.to_sym

      unless policy(resource).send("#{action}?")
        render_error('Access denied', :forbidden)
      end
    end

    private

    # Error handlers specific to API
    def handle_validation_error(exception)
      render_error(
        'Validation failed',
        :unprocessable_entity,
        exception.record.errors.full_messages
      )
    end

    def handle_not_found_api(exception = nil)
      render_error('Resource not found', :not_found)
    end

    def handle_missing_parameter(exception)
      render_error(
        "Missing required parameter: #{exception.param}",
        :bad_request
      )
    end

    def handle_unauthorized(exception = nil)
      render_error('Access denied', :forbidden)
    end

    # API version management
    def valid_api_version?(version)
      %w[v1].include?(version)
    end

    def api_version
      @api_version ||= request.headers['Accept-Version'] || params[:version] || 'v1'
    end

    # Token authentication
    def extract_token_from_header
      header = request.headers['Authorization']
      return nil unless header&.start_with?('Bearer ')

      header.split(' ', 2).last
    end

    def authenticate_with_token(token)
      # Implement your token authentication logic here
      # Example using JWT:
      # begin
      #   payload = JWT.decode(token, Rails.application.secrets.secret_key_base).first
      #   User.find(payload['user_id'])
      # rescue JWT::DecodeError
      #   nil
      # end

      # Temporary implementation - replace with your auth logic
      return nil unless token == 'valid_token'
      User.first # Replace with actual user lookup
    end

    # Rate limiting helper
    def check_rate_limit
      # Implement rate limiting logic here
      # Example using Redis:
      # key = "rate_limit:#{request.remote_ip}:#{Date.current}"
      # requests = Redis.current.incr(key)
      # Redis.current.expire(key, 24.hours) if requests == 1
      #
      # if requests > 1000 # 1000 requests per day
      #   render_error('Rate limit exceeded', :too_many_requests)
      # end
    end

    # Strong parameters helper for API
    def api_params(permitted_attributes)
      resource_name = controller_name.singularize
      params.require(resource_name).permit(permitted_attributes)
    end

    # CORS headers (if needed)
    def set_cors_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization'
    end
  end
end