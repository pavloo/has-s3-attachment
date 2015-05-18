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
        ssl = args[0] && args[0].key?(:ssl) ? args[0][:ssl] : true
        host_alias = self.class.host_alias
        if host_alias
          url_str = URI::HTTP.build(
            host: host_alias,
            path: s3_path
          ).to_s

          url_str.gsub!(/http/, 'https') if ssl

          url_str
        else
          @s3.bucket(s3_bucket).object(s3_path).public_url
        end
      end


      define_method("delete_#{attachment_name}".to_sym) do
        s3_bucket = send :"#{attachment_name}_s3_bucket"
        s3_path = send :"#{attachment_name}_s3_path"
        @s3.bucket(s3_bucket).object(s3_path).delete
      end

      define_method(:"open_#{attachment_name}") do |&block|
        url = send :"#{attachment_name}_url"
        open(url) do |f|
          block.call f
        end
      end

      define_method(:"#{attachment_name}_s3_bucket=") do |bucket|
        hash = s3_bucket_paths ? JSON.parse(s3_bucket_paths) : Hash.new
        hash["#{attachment_name}"] = {} unless hash.key? "#{attachment_name}"
        hash["#{attachment_name}"]['bucket'] = bucket
        self.s3_bucket_paths = JSON.generate(hash)
      end

      define_method(:"#{attachment_name}_s3_path=") do |path|
        hash = s3_bucket_paths ? JSON.parse(s3_bucket_paths) : Hash.new
        hash["#{attachment_name}"] = {} unless hash.key? "#{attachment_name}"
        hash["#{attachment_name}"]['path'] = path
        self.s3_bucket_paths = JSON.generate(hash)
      end

      define_method(:"#{attachment_name}_s3_bucket") do
        hash = s3_bucket_paths ? JSON.parse(s3_bucket_paths) : Hash.new
        hash["#{attachment_name}"]['bucket'] if hash.key? "#{attachment_name}"
      end

      define_method(:"#{attachment_name}_s3_path") do
        hash = s3_bucket_paths ? JSON.parse(s3_bucket_paths) : Hash.new
        hash["#{attachment_name}"]['path'] if hash.key? "#{attachment_name}"
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
end
