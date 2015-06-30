require "has_s3_attachment/version"
require "aws-sdk"
require "open-uri"
require "json"

module HasS3Attachment

  module ClassMethods
    def has_s3_attachment(attachment_name, options)
      @attachment_name = attachment_name
      set_s3_options(attachment_name, options[:s3_options])
      host_alias = options[:host_alias]

      define_method("#{attachment_name}_url".to_sym) do |*args|
        s3_bucket = send :"#{attachment_name}_s3_bucket"
        s3_path = send :"#{attachment_name}_s3_path"
        host = send :"#{attachment_name}_host_alias"
        host_alias = host || host_alias
        if host_alias
          ssl = args[0] && args[0].key?(:ssl) ? args[0][:ssl] : true
          url_str = URI::HTTP.build(
            host: host_alias,
            path: URI.escape(s3_path)
          ).to_s

          url_str.gsub!(/http/, 'https') if ssl && url_str

          url_str
        else
          @s3[attachment_name].bucket(s3_bucket).object(s3_path[1..-1]).public_url if s3_path && s3_bucket
        end
      end


      define_method("delete_#{attachment_name}".to_sym) do
        s3_bucket = send :"#{attachment_name}_s3_bucket"
        s3_path = send :"#{attachment_name}_s3_path"
        @s3[attachment_name].bucket(s3_bucket).object(s3_path[1..-1]).delete
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

      define_method(:"#{attachment_name}_host_alias=") do |host_alias|
        set_s3_paths(attachment_name, :host_alias, host_alias)
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

      define_method(:"#{attachment_name}_host_alias") do
        get_s3_paths(attachment_name, :host_alias)
      end
    end

    def set_s3_options(attachment_name, options)
      @s3_options = {} unless @s3_options
      @s3_options[attachment_name] = options
    end
  end

  def self.included(base)
    base.extend ClassMethods
    class << base
      attr_reader :s3_options, :host_alias, :attachment_name
    end

    base.after_find :init if base.respond_to?(:after_find)
  end

  def initialize(*args)
    super
    init
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

  def init
    s3_options = self.class.s3_options
    @s3 = {}
    s3_options.keys.each do |name|
      options = s3_options[name]
      if options
        @s3[name] = Aws::S3::Resource.new(
          region: options[:region],
          credentials: Aws::Credentials.new(options[:key], options[:secret])
        )
      else
        @s3[name] = Aws::S3::Client.new
      end
    end
  end
end
