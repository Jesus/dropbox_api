# DropboxApi

Library for communicating with Dropbox API v2.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dropbox_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dropbox_api

## Documentation

Please, refer to this gem's custom [Dropbox API
documentation](http://jesus.github.io/dropbox_api).
Most of the time you'll be checking the [available
endpoints](http://jesus.github.io/dropbox_api/DropboxApi/Client.html).

Unfortunately, the documentation at [RubyDoc.info](http://www.rubydoc.info) is
disrecommended because it lacks some nice features that have been added with
YARD plugins:

- Each endpoint includes its tests right below the description, this works as
  an example of its usage.
- All endpoints are shown as methods of the `Client` class, just as you will
  use them.

## Basic set up

### Authorize your application

Dropbox uses OAuth, in order to use this library from your application you'll
have to get an authorization code.

Once you have it, just pass it on client initialization:

```ruby
DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
```

Or set it as an ENV variable called `DROPBOX_OAUTH_BEARER`, for example:

```ruby
ENV["DROPBOX_OAUTH_BEARER"] = "VofXAX8D..."
DropboxApi::Client.new
#=> #<DropboxApi::Client ...>
```

Note that setting an ENV variable is only a feasible choice if you're only
using one account.


#### Option A: Get your access token from the website

The easiest way to obtain an access token is to get it from the Dropbox website.
You just need to log in to Dropbox and refer to the *developers* section, go to
*My apps* and select your application, you may need to create one if you
haven't done so yet.

Under your application settings, find section *OAuth 2*. You'll find a button
to generate an access token.

#### Option B: Use `DropboxApi::Authenticator`

You can obtain an authorization code with this library:

```ruby
authenticator = DropboxApi::Authenticator.new(CLIENT_ID, CLIENT_SECRET)
authenticator.auth_code.authorize_url #=> "https://www.dropbox.com/..."

# Now you need to open the authorization URL in your browser,
# authorize the application and copy your code.

auth_bearer = authenticator.auth_code.get_token(CODE) #=> #<OAuth2::AccessToken ...>`
auth_bearer.token #=> "VofXAX8D..."
# Keep this token, you'll need it to initialize a `DropboxApi::Client` object
```

#### Standard OAuth 2 flow

This is what many web applications will use. The process is described in
Dropbox's [OAuth guide](https://www.dropbox.com/developers/reference/oauth-guide#oauth-2-on-the-web).

If you have a Rails application, you might be interested in this [setup guide](http://jesus.github.io/dropbox_api/file.rails_setup.html).


### Authorize with short lived token

Dropbox introduces, effective on September, 30 2021, a new policy for OAuth2 token based authentication. It impacts all new applications as well as being suggested for existing apps. You can [read more about the change applied and how it impacts the authentication proces](https://dropbox.tech/developers/migrating-app-permissions-and-access-tokens#updating-access-token-type)

In short, the persistent, long lived tokens are being replaced with short lived tokens, which are valid for up to a few hours. With the current approach the application has to revalidate permission by executing a full handshake involving an interactive user to make a new token, which will expire.

Apps that require background ('offline') access but have not yet implemented refresh tokens will be impacted.

To keep “offline” access in the background the application must change authentication strategy and obtain a new token every time the old one expires with a simplified `refresh` procedure. The app performing a full token generation (the first step) must ask for special “offline” mode which will generate, except regular authentication, an additional refresh token that can be reused for future quick re-refresh procedures. Thus the refresh token is important and has to be securely stored with the application, as it will be required every time the short term token expires.

To prevent the app to lose connectivity and access to Dropbox resources using the library following changes has to be applied:

#### Implement own `DropboxApi::Token`

Application must replace current fixed token if it has used one with a dynamic, secure store that updates every time a token expires. For that purpose a new class `DropboxApi::Token` has been introduced, which implements short lived tokens, and replaces current fixed string approach.

Furthermore overriding the class on your own and implement `save_token` method allows to keep tokens within your application secure store or session data, every time needed.

```ruby
class MyDropboxToken < DropboxApi::Token
  def save_token(token)
    # Implement your own store method, token is a `Hash` instance in here, easy to serialize:
    puts 'Token to be saved somewhere in the database', token
  end
end
```

#### Obtaining the offline token

The application must obtain a new token for “offline use”.
In case of use of Authenticator approach, following change has to be applied:

```ruby
authenticator = DropboxApi::Authenticator.new(CLIENT_ID, CLIENT_SECRET)

# Change 1: ask for offline token type:
authenticator.auth_code.authorize_url(token_access_type: 'offline') #=> "https://www.dropbox.com/..."

# Now you need to open the authorization URL in your browser,
# authorize the application and copy your code.

# Change 2: Use own token to save it
token = MyDropboxToken.get_token(authenticator, CODE)  #=> #<DropboxApi::Token ...>`
# First save your data using overridden token implementation:
token.save!
```

#### Using A Token To Perform API Calls

```ruby
authenticator = DropboxApi::Authenticator.new(DROPBOX_APP_KEY, DROPBOX_APP_SECRET)

# Change 3: Use own class and the deserialized token to initialize the Client:

token_hash = DESERIALIZED_TOKEN_HASH # Implement your own method to load the hash from secure store
token = MyDropboxToken.new(authenticator, token_hash)

# Initialize API with a dynamic Token:
dropbox = DropboxApi::Client.new(token)

# Enjoy the API:
puts dropbox.get_metadata('/Temp/duck.jpg').to_hash
```

NOTE: When token expires it will automatically call refresh procedure in the background and invoke `save_token`
method from overridden class, to keep new token secure for the future use.

### Performing API calls

Once you've initialized a client, for example:

```ruby
client = DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
```

You can perform an API call like this:

```ruby
result = client.list_folder "/sample_folder"
#=> #<DropboxApi::Results::ListFolderResult>
result.entries
#=> [#<DropboxApi::Metadata::Folder>, #<DropboxApi::Metadata::File>]
result.has_more?
#=> false
```

The instance of `Client` we've initialized is the one you'll be using to
perform API calls. You can check the class' documentation to find
[all available endpoints](http://jesus.github.io/dropbox_api/DropboxApi/Client.html).

### Large file uploads

If you need to upload files larger than 150MB the default `#upload` endpoint
won't work. Instead, you need to start a upload session and upload
the file in small chunks.

To make this easier, the method `upload_by_chunks` will handle this for you,
example:

```ruby
client = DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
File.open("large_file.avi") do |f|
  client.upload_by_chunks "/remote_path.txt", f
end
```

Check out the
[method documentation](http://www.xuuso.com/dropbox_api/DropboxApi/Client.html#upload_by_chunks-instance_method)
to find out all available options.

### Accessing Team Folders

In order to access your team scope you need to add the namespace_id to you request headers.
This can be done using the middlewere layer as per the below:

```ruby
client = DropboxApi::Client.new("VofXAX8D...")
#=> #<DropboxApi::Client ...>
client.namespace_id = client.get_current_account.root_info.root_namespace_id

client.list_folder('')
#=> Now returns the team folders
```

You could unset the namespace ID at any point afterwards with just:

```ruby
client.namespace_id = nil
```

## Dependencies

This gem depends on
[oauth2](https://github.com/oauth-xx/oauth2)
and
[faraday](https://github.com/lostisland/faraday).

It has official support for Ruby versions `2.x`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

### Testing

I recommend you to use a test account other than your main one.

We use VCR to record the HTTP calls to Dropbox, however we sometimes need to
regenerate the cassettes. Let's take `list_folder` as an example to show what
would be the procedure to do so:

 1. Manually delete the existing cassettes in
    `spec/fixtures/vcr_cassettes/list_folder/*.yml`.

 2. Run the task to build the scaffolding in your Dropbox account so the tests
    will pass. If it doesn't exist you may need to write it yourself, check
    the `DropboxScaffoldBuilder` class to find all existing scaffold builders.

    ```text
    DROPBOX_OAUTH_BEARER=YOUR_AUTH_BEARER rake test:build_scaffold[list_folder]
    ```

    Note that you'll have to type `rake test:build_scaffold\[list_folder\]`
    if you use `zsh`.

    You can build all available scaffolds with just `rake test:build_scaffold`.

 3. Run the tests and the cassettes will be written:

    ```text
    DROPBOX_OAUTH_BEARER=YOUR_AUTH_BEARER rspec spec/endpoints/files/list_folder_spec.rb
    ```

The OAuth bearer shouldn't have been recorded in the cassette and it should've
been filtered. However, you may want to double check before pushing your
updates to Github.

Tip: you can simply run `export DROPBOX_OAUTH_BEARER=YOUR_AUTH_BEARER` at
the beginning of your work session so you don't need to prefix it in every
command line.

## Contributing

Any help will be much appreciated. The easiest way to help is to implement one
or more of the [endpoints that are still pending](http://jesus.github.io/dropbox_api/file.api_coverage.html). To see how the
endpoints are implemented, check out the `lib/dropbox_api/endpoints` folder.
