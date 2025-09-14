# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # CSRF protection
  protect_from_forgery with: :exception

  # Security headers
  before_action :set_security_headers

  # Error handling
  rescue_from StandardError, with: :handle_internal_server_error if Rails.env.production?
  rescue_from ActionController::RoutingError, with: :handle_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request

  # Logging
  before_action :log_request_info
  after_action :log_response_info

  protected

  # Set security headers for all responses
  def set_security_headers
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
  end

  # Request logging
  def log_request_info
    return unless Rails.env.development? || Rails.env.test?

    Rails.logger.info "Request: #{request.method} #{request.path}"
    Rails.logger.info "Params: #{params.except(:controller, :action, :authenticity_token).inspect}"
  end

  # Response logging
  def log_response_info
    return unless Rails.env.development? || Rails.env.test?

    Rails.logger.info "Response: #{response.status}"
  end

  # Current user helper (for authentication systems)
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  # Authentication check
  def authenticate_user!
    redirect_to login_path unless current_user
  end

  # Admin authentication
  def authenticate_admin!
    redirect_to root_path unless current_user&.admin?
  end

  private

  # Error handlers
  def handle_not_found(exception = nil)
    Rails.logger.warn "404 Not Found: #{exception&.message}"

    respond_to do |format|
      format.html { render 'errors/404', status: :not_found }
      format.json { render json: { error: 'Not Found' }, status: :not_found }
    end
  end

  def handle_bad_request(exception = nil)
    Rails.logger.warn "400 Bad Request: #{exception&.message}"

    respond_to do |format|
      format.html { render 'errors/400', status: :bad_request }
      format.json { render json: { error: 'Bad Request' }, status: :bad_request }
    end
  end

  def handle_internal_server_error(exception)
    Rails.logger.error "500 Internal Server Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    # Send to error tracking service (e.g., Sentry)
    # Sentry.capture_exception(exception) if defined?(Sentry)

    respond_to do |format|
      format.html { render 'errors/500', status: :internal_server_error }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
    end
  end

  # API response helpers
  def render_success(data = nil, message = 'Success', status = :ok)
    render json: {
      success: true,
      message: message,
      data: data
    }, status: status
  end

  def render_error(message = 'Error', status = :unprocessable_entity, errors = nil)
    render json: {
      success: false,
      message: message,
      errors: errors
    }, status: status
  end

  # Pagination helper
  def paginate_collection(collection, per_page: 20)
    collection.page(params[:page]).per(per_page)
  end

  # Strong parameters helper
  def permitted_params(*keys)
    params.require(controller_name.singularize.to_sym).permit(*keys)
  end
end