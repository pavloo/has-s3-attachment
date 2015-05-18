require "has_s3_attachment/version"
require "aws-sdk"
require "open-uri"

module HasS3Attachment

  module ClassMethods
    def has_s3_attachment(options)
      @s3_options = options[:s3_options]
      @host_alias = options[:host_alias]
    end
  end

  def self.included(base)
    base.extend ClassMethods
    class << base
      attr_reader :s3_options, :host_alias
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

  def attachment_url(ssl: true)
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

  def delete_attachment
    @s3.bucket(s3_bucket).object(s3_path).delete
  end

  def open_attachment
    open(attachment_url) do |f|
      yield f
    end
  end
end
