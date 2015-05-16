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
          s3_options: {
            region: 'us-west-2',
            key: 'key-xxx',
            secret: 'secret-xxx'
          }
        )

        attr_accessor :s3_bucket, :s3_path
      end.new
    end

    it 'generates attachment url' do
      subject.s3_bucket = 'bucket-name'
      subject.s3_path = 'path/to/file.txt'

      expect(subject.attachment_url).to eq 'https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt'
    end

    it 'removes attachment' do
      subject.s3_bucket = 'bucket-name'
      subject.s3_path = 'path/to/file.txt'

      stub_request(:delete, "https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt")

      subject.delete_attachment

      expect(subject.attachment_url).to eq 'https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt'
    end

    it "provides attachment's content stream" do
      subject.s3_bucket = 'bucket-name'
      subject.s3_path = 'path/to/file.txt'

      stub_request(:get, "https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt").
        to_return(:body => "dummy content")

      subject.open_attachment do |f|
        expect(f.read).to eq 'dummy content'
      end
    end
  end
end
