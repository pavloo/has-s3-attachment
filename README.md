# HasS3Attachment

A simple gem, which manages Rails model file attachments hosted on *aws s3*.

## Usage
Typical use case is when you have single paged web app backed by Rails app,
and you upload your attachments right from the browser to **s3** via `CORS` -
as a result you have only location of your file on **s3**. Then you may wanna link this attachment to some model in your app:

```ruby
class VideoReport < ActiveRecord::Base
  include HasS3Attachment

  has_s3_attachment(
    :video,
      s3_options: {
        region: 'us-west-2',
        key: 'key-xxx',
        secret: 'secret-xxx'
      },
      host_alias: 'cdn-example.com'
  )
end
```
To get it working you must have `s3_bucket_paths` attr of type `string` declared on your model.
Set **s3** location on an instance of your model as following (to associate your model with attachment):
```ruby
video_report.video_s3_bucket = 'your_bucket'
video_report.video_s3_path = '/path/to/file.mp4'
```
Then you'll be able to to call the next methods:
```ruby
video_report.video_url # returns full attachment url
video_report.delete_video # removes attachment from s3, may be used in conjunction with `before_destroy` ActiveRecord callback
video_report.open_video do |f|
  # f is an input stream of your attachment
end
```
## Multiple attachments, one model
You can add multiple attachments to your model like this:
```ruby
class User < ActiveRecord::Base
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
    :document,
    s3_options: {
      region: 'us-west-1',
      key: 'key-xxx1',
      secret: 'secret-xxx'
    }
  )
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'has_s3_attachment'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install has_s3_attachment

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/pavloo/has_s3_attachment/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
