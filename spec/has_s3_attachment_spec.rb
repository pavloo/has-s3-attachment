require 'spec_helper'

describe HasS3Attachment do
  it 'has a version number' do
    expect(HasS3Attachment::VERSION).not_to be nil
  end

  describe 'no host alias' do
    subject do
      Dummy = Class.new.send :include, HasS3Attachment
      Dummy.has_s3_attachment(
        s3_options: {
          region: 'us-west-2',
          key: 'key-xxx',
          secret: 'secret-xxx'
        }
      )

      class << Dummy
        attr_accessor :s3_bucket, :s3_path
      end

      Dummy.new
    end

    it 'generate attachment url' do
      subject.s3_bucket = 'bucket-name'
      subject.s3_path = 'path/to/file.txt'

      expect(subject.attachment_url).to eq 'https://bucket-name.s3.amazonaws.com/path/to/file.txt'
    end
  end
end
