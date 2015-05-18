require 'spec_helper'

describe HasS3Attachment do
  it 'has a version number' do
    expect(HasS3Attachment::VERSION).not_to be nil
  end

  describe 'no host alias' do
    subject do
      Class.new do
        include HasS3Attachment

        has_s3_attachment(
          :photo,
          s3_options: {
            region: 'us-west-2',
            key: 'key-xxx',
            secret: 'secret-xxx'
          }
        )

        attr_accessor :s3_bucket_paths
      end.new
    end

    it 'generates attachment url' do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = 'path/to/file.png'

      expect(subject.photo_url).to eq 'https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.png'
    end

    it 'removes attachment' do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = 'path/to/file.txt'

      stub_request(:delete, "https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt")

      subject.delete_photo
    end

    it "provides attachment's content stream" do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = 'path/to/file.txt'

      stub_request(:get, "https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt").
        to_return(:body => "dummy content")

      subject.open_photo do |f|
        expect(f.read).to eq 'dummy content'
      end
    end
  end

  describe 'with host alias' do
    subject do
      Class.new do
        include HasS3Attachment

        has_s3_attachment(
          :photo,
          s3_options: {
            region: 'us-west-2',
            key: 'key-xxx',
            secret: 'secret-xxx'
          },
          host_alias: 'cdn-example.com'
        )

        attr_accessor :s3_bucket_paths
      end.new
    end

    it 'generates attachment url, ssl on' do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = '/path/to/file.png'

      expect(subject.photo_url).to eq 'https://cdn-example.com/path/to/file.png'
    end

    it 'generates attachment url, ssl off' do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = '/path/to/file.txt'

      expect(subject.photo_url(ssl: false)).to eq 'http://cdn-example.com/path/to/file.txt'
    end
  end
end
