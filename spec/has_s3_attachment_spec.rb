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
      subject.photo_s3_path = '/path/to/file.png'

      expect(subject.photo_url).to eq 'https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.png'
    end

    it 'raises error if path is not absolute' do
      expect do
        subject.photo_s3_path = 'path/to/file.png'
      end.to raise_error('s3_path must be absolute and start with "/"')
    end

    it 'removes attachment' do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = '/path/to/file.txt'

      stub_request(:delete, "https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt")

      subject.delete_photo
    end

    it "provides attachment's content stream" do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = '/path/to/file.txt'

      stub_request(:get, "https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.txt").
        to_return(:body => "dummy content")

      subject.open_photo do |f|
        expect(f.read).to eq 'dummy content'
      end
    end

    # FIXME: add tests
    # it 'calls after find' do
    #   klass = Class.new do
    #     def after_find(arg)
    #       puts 'here'
    #     end
    #   end

    #   obj = klass.new do
    #     include HasS3Attachment

    #     has_s3_attachment(
    #       :photo,
    #       s3_options: {
    #         region: 'us-west-2',
    #         key: 'key-xxx',
    #         secret: 'secret-xxx'
    #       }
    #     )
    #     attr_accessor :s3_bucket_paths
    #   end

    #   obj
    # end
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

    it 'overrides global host_alias' do
      subject.photo_s3_bucket = 'bucket-name'
      subject.photo_s3_path = '/path/to/file.txt'
      subject.photo_host_alias = 'cdn-example-overriden.com'

      expect(subject.photo_url).to eq 'https://cdn-example-overriden.com/path/to/file.txt'
    end
  end

  describe 'dynamic paths attributes' do
    it 'raises NameError if no s3_bucket_paths attr' do
      obj = Class.new do
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
      end.new

      expect do
        obj.photo_s3_bucket = 'bucket-name'
      end.to raise_error(NameError, 'You must create model attribute "s3_bucket_paths" of type string in order to make has_s3_attachment work')
      expect do
        obj.photo_s3_path = '/path/to/file.png'
      end.to raise_error(NameError, 'You must create model attribute "s3_bucket_paths" of type string in order to make has_s3_attachment work')
    end
  end

  describe 'multiple attachments' do
    it 'creates multiple attachments' do
      obj = Class.new do
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

        has_s3_attachment(
          :file,
          s3_options: {
            region: 'us-west-1',
            key: 'key-xxx1',
            secret: 'secret-xxx'
          }
        )

        attr_accessor :s3_bucket_paths
      end.new

      obj.photo_s3_bucket = 'bucket-name'
      obj.photo_s3_path = '/path/to/file.png'

      obj.file_s3_bucket = 'bucket-name1'
      obj.file_s3_path = '/path/to/file.txt'

      expect(obj.photo_url).to eq('https://cdn-example.com/path/to/file.png')
      expect(obj.file_url).to eq('https://bucket-name1.s3-us-west-1.amazonaws.com/path/to/file.txt')

      stub_request(:delete, 'https://bucket-name.s3-us-west-2.amazonaws.com/path/to/file.png')
      stub_request(:delete, 'https://bucket-name1.s3-us-west-1.amazonaws.com/path/to/file.txt')

      obj.delete_photo
      obj.delete_file
    end
  end
end
