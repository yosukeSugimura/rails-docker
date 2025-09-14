# frozen_string_literal: true

RSpec.shared_context 'API request helpers' do
  let(:json_response) { JSON.parse(response.body) }
  let(:json_headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let(:auth_headers) { { 'Authorization' => "Bearer #{auth_token}" } }
  let(:api_headers) { json_headers.merge(auth_headers) }
  let(:auth_token) { 'valid_token' }

  # Helper methods for API testing
  def json_get(path, headers: {})
    get path, headers: json_headers.merge(headers)
  end

  def json_post(path, params: {}, headers: {})
    post path, params: params.to_json, headers: json_headers.merge(headers)
  end

  def json_put(path, params: {}, headers: {})
    put path, params: params.to_json, headers: json_headers.merge(headers)
  end

  def json_patch(path, params: {}, headers: {})
    patch path, params: params.to_json, headers: json_headers.merge(headers)
  end

  def json_delete(path, headers: {})
    delete path, headers: json_headers.merge(headers)
  end

  # Authenticated API requests
  def auth_get(path, headers: {})
    get path, headers: api_headers.merge(headers)
  end

  def auth_post(path, params: {}, headers: {})
    post path, params: params.to_json, headers: api_headers.merge(headers)
  end

  def auth_put(path, params: {}, headers: {})
    put path, params: params.to_json, headers: api_headers.merge(headers)
  end

  def auth_patch(path, params: {}, headers: {})
    patch path, params: params.to_json, headers: api_headers.merge(headers)
  end

  def auth_delete(path, headers: {})
    delete path, headers: api_headers.merge(headers)
  end

  # Response assertion helpers
  def expect_success_response(message: 'Success', data: nil)
    expect(response).to have_http_status(:ok)
    expect(json_response).to include(
      'success' => true,
      'message' => message
    )
    expect(json_response['data']).to eq(data) if data
  end

  def expect_error_response(status: :unprocessable_entity, message: 'Error', errors: nil)
    expect(response).to have_http_status(status)
    expect(json_response).to include(
      'success' => false,
      'message' => message
    )
    expect(json_response['errors']).to eq(errors) if errors
  end

  def expect_validation_errors(*field_names)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_response).to include('success' => false)

    field_names.each do |field|
      expect(json_response['errors']).to be_any { |error| error.include?(field.to_s) }
    end
  end

  def expect_not_found
    expect_error_response(status: :not_found, message: 'Resource not found')
  end

  def expect_unauthorized
    expect_error_response(status: :unauthorized, message: 'Authentication required')
  end

  def expect_forbidden
    expect_error_response(status: :forbidden, message: 'Access denied')
  end

  # Pagination helpers
  def expect_paginated_response(page: 1, per_page: 20, total_count: nil)
    expect(json_response['data']).to include(
      'pagination' => include(
        'current_page' => page,
        'per_page' => per_page
      )
    )

    if total_count
      expect(json_response['data']['pagination']).to include(
        'total_count' => total_count
      )
    end
  end

  # API versioning helpers
  def with_api_version(version)
    original_headers = @request&.headers&.dup || {}

    if @request
      @request.headers['Accept-Version'] = version
    end

    yield
  ensure
    if @request && original_headers
      @request.headers = original_headers
    end
  end

  # Time helpers
  def freeze_time(time = Time.current)
    travel_to(time) { yield }
  end

  # Database helpers
  def with_clean_database
    DatabaseCleaner.clean_with(:truncation)
    yield
  ensure
    DatabaseCleaner.clean_with(:truncation)
  end
end

# Performance testing helpers
RSpec.shared_context 'Performance testing' do
  def measure_time
    start_time = Time.current
    yield
    Time.current - start_time
  end

  def expect_response_time_under(seconds)
    response_time = measure_time { yield }
    expect(response_time).to be < seconds
  end
end

# Authentication helpers
RSpec.shared_context 'Authentication helpers' do
  let(:user) { create(:user) if defined?(FactoryBot) }
  let(:admin_user) { create(:admin_user) if defined?(FactoryBot) }

  def login_as(user)
    session[:user_id] = user.id
  end

  def logout
    session[:user_id] = nil
  end

  def with_current_user(user)
    original_user_id = session[:user_id]
    session[:user_id] = user.id
    yield
  ensure
    session[:user_id] = original_user_id
  end
end