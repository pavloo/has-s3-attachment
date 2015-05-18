require "has_s3_attachment/version"
require "aws-sdk"
require "open-uri"

module HasS3Attachment

  module ClassMethods
    def has_s3_attachment(attachment_name, options)
      @attachment_name = attachment_name
      @s3_options = options[:s3_options]
      @host_alias = options[:host_alias]

      define_method("#{attachment_name}_url".to_sym) do |*args|
        s3_bucket = send :"#{attachment_name}_s3_bucket"
        s3_path = send :"#{attachment_name}_s3_path"
        host_alias = self.class.host_alias
        if host_alias
          ssl = args[0] && args[0].key?(:ssl) ? args[0][:ssl] : true
          url_str = URI::HTTP.build(
            host: host_alias,
            path: s3_path
          ).to_s

          url_str.gsub!(/http/, 'https') if ssl

          url_str
        else
          @s3.bucket(s3_bucket).object(s3_path[1..-1]).public_url
        end
      end


      define_method("delete_#{attachment_name}".to_sym) do
        s3_bucket = send :"#{attachment_name}_s3_bucket"
        s3_path = send :"#{attachment_name}_s3_path"
        @s3.bucket(s3_bucket).object(s3_path[1..-1]).delete
      end

      define_method(:"open_#{attachment_name}") do |&block|
        url = send :"#{attachment_name}_url"
        open(url) do |f|
          block.call f
        end
      end

      define_method(:"#{attachment_name}_s3_bucket=") do |bucket|
        set_s3_paths(attachment_name, :bucket, bucket)
      end

      define_method(:"#{attachment_name}_s3_path=") do |path|
        fail 's3_path must be absolute and start with "/"' unless path.start_with?('/')
        set_s3_paths(attachment_name, :path, path)
      end

      define_method(:"#{attachment_name}_s3_bucket") do
        get_s3_paths(attachment_name, :bucket)
      end

      define_method(:"#{attachment_name}_s3_path") do
        get_s3_paths(attachment_name, :path)
      end
    end
  end

  def self.included(base)
    base.extend ClassMethods
    class << base
      attr_reader :s3_options, :host_alias, :attachment_name
    end
  end

  def initialize
    super
    s3_options = self.class.s3_options
    if s3_options
      @s3 = Aws::S3::Resource.new(
        region: s3_options[:region],
        credentials: Aws::Credentials.new(s3_options[:key], s3_options[:secret])
      )
    else
      @s3 = Aws::S3::Client.new
    end
  end

  private

  def set_s3_paths(name, type, value)
    begin
      hash = s3_bucket_paths ? JSON.parse(s3_bucket_paths) : Hash.new
    rescue NameError => e
      raise NameError, 'You must create model attribute "s3_bucket_paths" of type string in order to make has_s3_attachment work'
    end
    hash["#{name}"] = {} unless hash.key? "#{name}"
    hash["#{name}"][type.to_s] = value
    self.s3_bucket_paths = JSON.generate(hash)
  end

  def get_s3_paths(name, type)
    begin
      hash = s3_bucket_paths ? JSON.parse(s3_bucket_paths) : Hash.new
    rescue NameError => e
      raise NameError, 'You must create model attribute "s3_bucket_paths" of type string in order to make has_s3_attachment work'
    end
    hash["#{name}"][type.to_s] if hash.key? "#{name}"
  end
end
