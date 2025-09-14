require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsDocker
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Application configuration
    config.time_zone = 'Asia/Tokyo'
    config.version = ENV.fetch('APP_VERSION', '1.0.0')

    # I18n configuration
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [:ja, :en]
    config.i18n.fallbacks = true

    # Encoding
    config.encoding = 'utf-8'

    # Security configurations
    config.force_ssl = Rails.env.production?
    config.ssl_options = {
      redirect: { exclude: ->(request) { request.path =~ /health/ } }
    } if Rails.env.production?

    # CORS configuration (if needed for API)
    if defined?(Rack::Cors)
      config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins '*'
          resource '/api/*',
                   headers: :any,
                   methods: [:get, :post, :put, :patch, :delete, :options, :head],
                   expose: ['X-Total-Count', 'X-Page', 'X-Per-Page']
        end

        allow do
          origins '*'
          resource '/health*',
                   headers: :any,
                   methods: [:get, :options, :head]
        end
      end
    end

    # Active Job configuration
    config.active_job.queue_adapter = :sidekiq

    # Cache store configuration
    if defined?(Redis)
      config.cache_store = :redis_cache_store, {
        url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
        expires_in: 1.hour,
        namespace: 'rails_docker_cache'
      }
    else
      config.cache_store = :memory_store, { size: 64.megabytes }
    end

    # Session store configuration (fallback to cookie store if Redis not available)
    if defined?(ActionDispatch::Session::RedisStore)
      config.session_store :redis_store,
        servers: [ENV.fetch('REDIS_URL', 'redis://localhost:6379/2')],
        expire_in: 30.days,
        key: '_rails_docker_session',
        secure: Rails.env.production?,
        httponly: true,
        same_site: :lax
    else
      config.session_store :cookie_store,
        key: '_rails_docker_session',
        secure: Rails.env.production?,
        httponly: true,
        same_site: :lax
    end

    # Log configuration
    config.log_level = ENV.fetch('LOG_LEVEL', 'info').to_sym
    config.log_tags = [:request_id, :remote_ip]

    # Generator configuration
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.view_specs false
      g.helper_specs false
      g.routing_specs false
      g.controller_specs false
      g.request_specs true
    end

    # Autoload paths
    config.autoload_paths += %W[
      #{config.root}/lib
      #{config.root}/app/services
      #{config.root}/app/serializers
    ]

    # Custom configurations
    config.api_v1_features = %w[
      authentication
      pagination
      filtering
      sorting
    ]

    # Exception handling in production
    if Rails.env.production?
      config.exceptions_app = routes
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
