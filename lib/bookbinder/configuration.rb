class Configuration
  class AwsCredentials
    REQUIRED_KEYS = %w(access_key secret_key green_builds_bucket).freeze

    def initialize(cred_hash)
      @creds = cred_hash
    end

    REQUIRED_KEYS.each do |method_name|
      define_method(method_name) do
        creds.fetch(method_name)
      end
    end

    private

    attr_reader :creds
  end

  class CfCredentials
    REQUIRED_KEYS = %w(api_endpoint organization app_name).freeze
    OPTIONAL_KEYS = %w(username password).freeze

    def initialize(cred_hash, is_production)
      @creds = cred_hash
      @is_production = is_production
    end

    REQUIRED_KEYS.each do |method_name|
      define_method(method_name) do
        creds.fetch(method_name)
      end
    end

    OPTIONAL_KEYS.each do |method_name|
      define_method(method_name) do
        creds.fetch(method_name, nil)
      end
    end

    def host
      key = is_production ? 'production_host' : 'staging_host'
      creds.fetch(key)
    end

    def space
      key = is_production ? 'production_space' : 'staging_space'
      creds.fetch(key)
    end

    private

    attr_reader :creds, :is_production
  end

  def initialize(config_hash)
    @config = config_hash
  end

  %w(book_repo cred_repo repos public_host).each do |method_name|
    define_method(method_name) do
      config.fetch(method_name)
    end
  end

  def template_variables
    config.fetch('template_variables', {})
  end

  def aws_credentials
    @aws_creds ||= AwsCredentials.new(credentials.fetch('aws'))
  end

  def cf_staging_credentials
    @cf_staging_creds ||= CfCredentials.new(credentials.fetch('cloud_foundry'), false)
  end

  def cf_production_credentials
    @cf_prod_creds ||= CfCredentials.new(credentials.fetch('cloud_foundry'), true)
  end

  def ==(o)
    (o.class == self.class) && (o.config == self.config)
  end

  alias_method :eql?, :==

  protected

  attr_reader :config

  private

  def credentials
    @credentials ||= CredRepo.new(full_name: cred_repo).credentials
  end
end
