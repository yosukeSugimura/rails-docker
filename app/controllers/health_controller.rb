# frozen_string_literal: true

class HealthController < ApplicationController
  # Skip authentication and CSRF for health checks
  skip_before_action :verify_authenticity_token

  # Basic health check endpoint
  def show
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || '1.0.0',
      environment: Rails.env
    }, status: :ok
  end

  # Detailed health check with database connectivity
  def detailed
    checks = perform_health_checks

    status = checks.all? { |check| check[:status] == 'ok' } ? 'ok' : 'error'
    http_status = status == 'ok' ? :ok : :service_unavailable

    render json: {
      status: status,
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || '1.0.0',
      environment: Rails.env,
      checks: checks
    }, status: http_status
  end

  # Readiness probe for Kubernetes
  def ready
    checks = perform_readiness_checks

    if checks.all? { |check| check[:status] == 'ok' }
      render json: { status: 'ready' }, status: :ok
    else
      render json: {
        status: 'not_ready',
        checks: checks.select { |check| check[:status] != 'ok' }
      }, status: :service_unavailable
    end
  end

  # Liveness probe for Kubernetes
  def live
    render json: {
      status: 'alive',
      timestamp: Time.current.iso8601
    }, status: :ok
  end

  private

  def perform_health_checks
    [
      check_database,
      check_redis,
      check_disk_space,
      check_memory
    ].compact
  end

  def perform_readiness_checks
    [
      check_database,
      check_redis
    ].compact
  end

  def check_database
    start_time = Time.current

    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      duration = ((Time.current - start_time) * 1000).round(2)

      {
        name: 'database',
        status: 'ok',
        duration_ms: duration,
        details: {
          adapter: ActiveRecord::Base.connection.adapter_name,
          database: ActiveRecord::Base.connection.current_database
        }
      }
    rescue => e
      {
        name: 'database',
        status: 'error',
        error: e.message,
        duration_ms: ((Time.current - start_time) * 1000).round(2)
      }
    end
  end

  def check_redis
    return nil unless defined?(Redis)

    start_time = Time.current

    begin
      redis_client = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
      redis_client.ping
      duration = ((Time.current - start_time) * 1000).round(2)

      {
        name: 'redis',
        status: 'ok',
        duration_ms: duration,
        details: {
          url: ENV['REDIS_URL'] || 'redis://localhost:6379'
        }
      }
    rescue => e
      {
        name: 'redis',
        status: 'error',
        error: e.message,
        duration_ms: ((Time.current - start_time) * 1000).round(2)
      }
    ensure
      redis_client&.close
    end
  end

  def check_disk_space
    begin
      stat = File.statvfs(Rails.root)
      total_space = stat.blocks * stat.frsize
      free_space = stat.bavail * stat.frsize
      used_percentage = ((total_space - free_space).to_f / total_space * 100).round(2)

      status = used_percentage > 90 ? 'warning' : 'ok'

      {
        name: 'disk_space',
        status: status,
        details: {
          total_gb: (total_space / 1024.0 / 1024.0 / 1024.0).round(2),
          free_gb: (free_space / 1024.0 / 1024.0 / 1024.0).round(2),
          used_percentage: used_percentage
        }
      }
    rescue => e
      {
        name: 'disk_space',
        status: 'error',
        error: e.message
      }
    end
  end

  def check_memory
    begin
      if File.exist?('/proc/meminfo')
        meminfo = File.read('/proc/meminfo')
        total_match = meminfo.match(/MemTotal:\s+(\d+)\s+kB/)
        available_match = meminfo.match(/MemAvailable:\s+(\d+)\s+kB/)

        if total_match && available_match
          total_kb = total_match[1].to_i
          available_kb = available_match[1].to_i
          used_percentage = ((total_kb - available_kb).to_f / total_kb * 100).round(2)

          status = used_percentage > 90 ? 'warning' : 'ok'

          {
            name: 'memory',
            status: status,
            details: {
              total_mb: (total_kb / 1024.0).round(2),
              available_mb: (available_kb / 1024.0).round(2),
              used_percentage: used_percentage
            }
          }
        end
      end
    rescue => e
      {
        name: 'memory',
        status: 'error',
        error: e.message
      }
    end
  end

end