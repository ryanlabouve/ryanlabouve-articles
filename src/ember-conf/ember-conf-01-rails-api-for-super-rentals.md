
Let's be dumb and feel our way through making this API.
This is important because:
* "Address only what's necessary"
* We have a design and all we need to do is ensure implementation
If you are newer to Rails (or returning after a long break)... we will practice
* Red, green, refactor
* Outside-in development
Some things I know I want, but I'm too lazy to explain/justify :waves-hands:
* Rails to be API only
* To use RSpec to test
* To use Postgres

## The design
Our scenarios:

```
We can get a list of all rentals
`GET /rentals`
We can list a single rental
`GET /rentals/:id`
We can filter by a query param
`GET /rentals?city=[city_name]`
Some other considerations
* JSON API compliant
```

## To start a basic API

```
# --database=postgres gets us out of sqlite hell
# -T skips installing minitest, which ships default with rails
# --api skips installed all of the HTML/CSS/JS/non-api stuffs that comes by default
rails new super-rentals-api -T --api --database=postgresql
cd super-rentals-api
# setup any local ruby setup.. for me that is:
# asdf local ruby 2.4.2
# Commit it before you forget it
git add .
git commit -m "Initial commit"
```

### Setup Rspec

```
# gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'database_cleaner'
end
```

Setup basic spec directory (https://stackoverflow.com/a/21323315)
```
rails generate rspec:install
createuser -s -r super-rentals-api
bundle exec rake db:create:all
```

Clean database between transactions
```
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
```

Remove this line
```
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  - config.fixture_path = "#{::Rails.root}/spec/fixtures"
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
```

Request level tests
```
mkdir spec/requests
```

Write our first spec
```
# spec/requests/list_rentals_spec.rb
require "rails_helper"

describe "/GET rentals", type: :request do
  it "lists rentals" do
      get "/api/rentals"
      # Let's just make sure we get some positive response
      expect(response.status).to eq(200)
  end
end
```

Running first spec:
```
Failures:

  1) /GET rentals lists rentals
     Failure/Error: get "/api/rentals"

     ActionController::RoutingError:
       No route matches [GET] "/api/rentals"
     # ./spec/requests/get_rentals_spec.rb:6:in `block (2 levels) in <top (required)>'

Finished in 0.19419 seconds (files took 2.23 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/requests/get_rentals_spec.rb:5 # /GET rentals lists rentals
```

## Let's get a response

At every corner, let's do the smallest thing
We could blaze through this with a few generators, but the point of this exercise is to illuminate/educate. So we will stumble through this one failure at a time.
This also means we "only build what is necessary" and also strictly implement the design.

### Failure 1: Routing error
Let's make the new route, with only the action we need.
Rails.application.routes.draw do

```
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api do
    resources :rentals, only: [:index]
  end
end
```

Re-run test:

```
Failures:

  1) /GET rentals lists rentals
     Failure/Error: get "/api/rentals"

     ActionController::RoutingError:
       uninitialized constant RentalsController
     # ./spec/requests/get_rentals_spec.rb:6:in `block (2 levels) in <top (required)>'
     # ------------------
     # --- Caused by: ---
     # NameError:
     #   uninitialized constant RentalsController
     #   ./spec/requests/get_rentals_spec.rb:6:in `block (2 levels) in <top (required)>'

Finished in 0.03898 seconds (files took 2.33 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/requests/get_rentals_spec.rb:5 # /GET rentals lists rentals
```

### Failure 2: Initialized Constant RentalsController

```
# app/controllers/api/rentals_controller.rb
module Api
  class RentalsController < ApplicationController
  end
end
```

Now our action is not found
Failures:

```
  1) /GET rentals lists rentals
     Failure/Error: get "/api/rentals"

     AbstractController::ActionNotFound:
       The action 'index' could not be found for Api::RentalsController
     # ./spec/requests/get_rentals_spec.rb:6:in `block (2 levels) in <top (required)>'

Finished in 0.04173 seconds (files took 2.2 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/requests/get_rentals_spec.rb:5 # /GET rentals lists rentals
```

### Failure 3: Making the action
```
module Api
  class RentalsController < ApplicationController
    + def index
    + end
  end
end
```

now there are no spec failures:

```
.

Finished in 0.05321 seconds (files took 2.65 seconds to load)
1 example, 0 failures
```

## What's the next pass?
Here is where we are all attempted to just assume that we know what's next. Anyone who's done this before will start having a long list in their head (CORS, accept headers, etc)... but let's try to keep being dumb.
Let's cut over to the actuall app and see what blow up! We can treat everything doesn't doesn't work as a regression. 

(Why? Because based on my next most clear picture of where this will fail on the consumer, this is it. )

Booting up the app shows pure fails! And if we navigate to the dev console, this is what we see:
```
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at http://localhost:3000/api/rentals. (Reason: CORS header ‘Access-Control-Allow-Origin’ missing).
```

https://jbilbo.com/blog/2015/05/19/testing-cors-with-rspec/

IF we are treating this like a regression, what do we do next?

`‘Access-Control-Allow-Origin’ missing`

So let's reproduce this with a failing test..

```
require 'rails_helper'

# Current state of the world...
# Our requests are getting blocked by the client because `Access-Control-Allow-Origin`
describe "Any request", type: :request do
  it "should have `Access-Control-Allow-Origin` header" do
    # I pulled this header off of the network tab in the browser
    # without it, no CORS headers are sent back with request
    headers = {
      "ORIGIN" => "http://localhost:4586"
    }

    get '/api/rentals', params: nil, headers: headers

    expect(response.headers['Access-Control-Allow-Origin']).not_to be_empty
  end
end
```

And we have a failure.
Let's install and configure rack/cors.
```
gem 'rack-cors', require: 'rack/cors'

# config/application.rb
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :options, :patch]
      end
    end
```

Passing. Let's see what's not working next.

http://arnab-deka.com/posts/2012/09/allowing-and-testing-cors-requests-in-rails/
https://gist.github.com/arnab/3749227
https://jbilbo.com/blog/2015/05/19/testing-cors-with-rspec/


## Getting some JSON-API

From the console
```
but the adapter's response did not have any data
https://github.com/emberjs/data/blob/ebd4de2c990f5d3d603316da48ba14cdb99f919d/addon/-private/system/store/finders.js#L404
assert( 
`You made a 'findAll' request for '${modelName}' records, but the adapter's response did not have any data`, 
payloadIsNotBlank(adapterPayload) 
);
```

### Red
```
describe "/GET rentals", type: :request do
  it "lists rentals" do
      get "/api/rentals"
      expect(response).to have_http_status(:success)
      + expect(response.body).not_to be_empty
  end
end
```

### Green

```
module Api
  class RentalsController < ApplicationController
    def index
      render json: []
    end
  end
end
```

### Another Regression
```
rentals.index Assertion Failed: normalizeResponse must return a valid JSON API document:
```

Makes sense. Let's use something to render a JSON API document...
We'll start with a failing test (which will prove more complicated than I'd like)
Following suit of: 
https://thoughtbot.com/blog/validating-json-schemas-with-an-rspec-matcher
https://medium.com/@igor_marques/writing-custom-matchers-15bd3d866079
https://thoughtbot.com/blog/four-phase-test
* We can just put the matcher directly in spec helpers... i ended up adding this line so I could follow suit of the thoughtbot post (advice from https://makandracards.com/makandra/1115-where-to-put-custom-rspec-matchers)

```
# spec/spec_helper.rb
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}
RSpec::Matchers.define :probably_be_json_api do |model|
  match do |response|
    parsed_body = JSON.parse(response.body)
    return parsed_body.key?("data") || parsed_body.key?("errors") ? true : false
  end
end
```

## Fail!
```
# my 2 cent jsonapi validator
      expect(response).to probably_be_json_api
```

## Fix
https://github.com/Netflix/fast_jsonapi
```
gem 'fast_jsonapi'
rails g serializer Rental
```

```
module Api
  class RentalsController < ApplicationController
    def index
      render json: RentalSerializer.new([]).serialized_json
    end
  end
end
```

Refresh the Ember app and now Super rentals just thinks we don't have any rentals.

## Enter the Rentals

Install and use FactoryBot (formally known as FactoryGirl)

```
gem 'factory_bot_rails'
```

And in your spec config
```
  # Config Factory Bot
  # https://www.rubydoc.info/gems/factory_bot/file/GETTING_STARTED.md
  config.include FactoryBot::Syntax::Method
Create new spec in our Rentals file
  it "lists 3 rentals when I have 3 rentals" do
    rentals = create_list(:rental, 3)
  end
```

And now, for what we've been slowly moving towards! (but probably would have started with if we were not TDDDD)

```
  1) /GET rentals lists 3 rentals when I have 3 rentals
     Failure/Error: rentals = create_list(:rental, 3)
     
     NameError:
       uninitialized constant Rental
     # ./spec/requests/get_rentals_spec.rb:20:in `block (2 levels) in <main>'
     # ------------------
     # --- Caused by: ---
     # NameError:
     #   uninitialized constant Rental
     #   ./spec/requests/get_rentals_spec.rb:20:in `block (2 levels) in <main>'

Finished in 0.09982 seconds (files took 4.05 seconds to load)
3 examples, 1 failure
```

FINALLY we can make the Rental model
rails g model Rental
Green.
```
  it "lists 3 rentals when I have 3 rentals" do
    rentals = create_list(:rental, 3)

    get "/api/rentals"

    body = JSON.parse(response.body)
    data = body.dig("data")

    expect(response).to have_http_status(:success)
    expect(response).to probably_be_json_api
    # binding.pry
    expect(data.length).to equal(3)
  end
```

Now let's make our controller return all the rentals
```
module Api
  class RentalsController < ApplicationController
    def index
      @rentals = Rental.all
      render json: RentalSerializer.new(@rentals).serialized_json
    end
  end
end
```

What can we ignore/what can we not?
Making the model

```
class AddsColsToRental < ActiveRecord::Migration[5.2]
  def change
    add_column :rentals, :title, :string
    add_column :rentals, :owner, :string
    add_column :rentals, :city, :string
    add_column :rentals, :category, :string
    add_column :rentals, :image, :string
    add_column :rentals, :bedrooms, :integer
    add_column :rentals, :description, :text
  end
end
```

```
  it "lists 3 rentals when I have 3 rentals" do
    rentals = create_list(:rental, 3)

    get "/api/rentals"

    body = JSON.parse(response.body)
    data = body.dig("data")

    expect(response).to have_http_status(:success)
    expect(response).to probably_be_json_api
    # binding.pry
    expect(data.length).to equal(3)

    # Smoke test one of the rentals

    # TODO: we are assuming sorting for now
    first_rental = data[0]
    expect(first_rental.dig("attributes", "title")).to eq(rentals.first.title)
    expect(first_rental.dig("attributes", "owner")).to eq(rentals.first.owner)
    expect(first_rental.dig("attributes", "city")).to eq(rentals.first.city)
    expect(first_rental.dig("attributes", "category")).to eq(rentals.first.category)
    expect(first_rental.dig("attributes", "bedrooms")).to eq(rentals.first.bedrooms)
    expect(first_rental.dig("attributes", "description")).to eq(rentals.first.description)
  end
```

```
class RentalSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title, :owner, :city, :category, :bedrooms, :description
end
```

Test with actual ember app?

The Second Scenario
We can list a single rental
```
`GET /rentals/:id`
```

Red!
```
describe "GET /rentals/:id", type: :request do
  it "returns the details of a single rental" do
    rental = create(:rental)

    get "/api/rentals/#{rental.id}"
  end
end
```
New regression
```
  1) GET /rentals/:id returns the details of a single rental
     Failure/Error: get "/api/rentals/#{rental.id}"
     
     ActionController::RoutingError:
       No route matches [GET] "/api/rentals/4"
     # ./spec/requests/get_rentals_spec.rb:53:in `block (2 levels) in <main>'
```

### Add route

```
# config/routes.rb
resources :rentals, only: [:index, :get]
```

### Action not found
```
1) AbstractController::ActionNotFound:
       The action 'show' could not be found for Api::RentalsController
    def show
    end
```

### Green, next thing
```
describe "GET /rentals/:id", type: :request do
  it "returns the details of a single rental" do
    rental = create(:rental)

    get "/api/rentals/#{rental.id}"

    body = JSON.parse(response.body)
    data = body.dig("data")

    expect(response).to have_http_status(:success)
    expect(response).to probably_be_json_api

    response_rental = data
    expect(response_rental.dig("attributes", "title")).to eq(rental.title)
    expect(response_rental.dig("attributes", "owner")).to eq(rental.owner)
    expect(response_rental.dig("attributes", "city")).to eq(rental.city)
    expect(response_rental.dig("attributes", "category")).to eq(rental.category)
    expect(response_rental.dig("attributes", "bedrooms")).to eq(rental.bedrooms)
    expect(response_rental.dig("attributes", "description")).to eq(rental.description)
  end
end
```

```
module Api
  class RentalsController < ApplicationController
    def index
      @rentals = Rental.all
      render json: RentalSerializer.new(@rentals).serialized_json
    end

    def show
      @rental = rental
      render json: RentalSerializer.new(@rental).serialized_json
    end

    private

    # def rental_params
    #   binding.pry
    #   params.require(:data)
    # end

    def rental
      Rental.find(params[:id])
    end
  end
end
```

And the last scenario

Specs
```
describe "GET /rentals?city=[search_term]" do
  it "returns a list of rentals given the search_term" do
    new_orleans_rental = create(:rental, {
      city: "New Orleans"
    })

    oklahoma_city_rental = create(:rental, {
      city: "Oklahoma City"
    })

    get "/api/rentals?city=okla"

    body = JSON.parse(response.body)
    data = body.dig("data")

    expect(response).to have_http_status(:success)
    expect(response).to probably_be_json_api

    expect(data.length).to equal(1)

    first_rental = data[0]

    expect(first_rental.dig("attributes", "city")).to eq("Oklahoma City")
  end

  it "returns nothing if there are no matching results" do
    new_orleans_rental = create(:rental, {
      city: "New Orleans"
    })

    oklahoma_city_rental = create(:rental, {
      city: "Oklahoma City"
    })

    get "/api/rentals?city=San"

    body = JSON.parse(response.body)
    data = body.dig("data")

    expect(response).to have_http_status(:success)
    expect(response).to probably_be_json_api
    expect(data.length).to equal(0)
  end
```

Implementation

```
module Api
  class RentalsController < ApplicationController
    def index
      @rentals = Rental

      if search_terms[:city].present?
        @rentals = @rentals.where("lower(city) LIKE lower(?)", "%#{search_terms[:city]}%")
      end
      @rentals = @rentals.all

      render json: RentalSerializer.new(@rentals).serialized_json
    end

    def show
      @rental = rental
      render json: RentalSerializer.new(@rental).serialized_json
    end

    private

    # def rental_params
    #   binding.pry
    #   params.require(:data)
    # end
    def rental
      Rental.find(params[:id])
    end

    def search_terms
      params.permit(:city)
    end
  end
end
```



Mentioned 3rd party tools
FactoryBot: DSL for creating demo data.
Shoulda matchers
Database clearers

https://blog.codeship.com/the-json-api-spec/
Validating JSON Schema
https://thoughtbot.com/blog/validating-json-schemas-with-an-rspec-matcher
"Test driven RSPEC".... looks like the thoughtbot tutorial but for APIs
https://www.youtube.com/watch?v=Wb3oIfiLdZU
Setting mime types
Using factory bot
This is very similar to what I need
https://semaphoreci.com/community/tutorials/behavior-driven-rails-5-api-for-an-ember-js-application

Rails 4 in action book may have this....
Have used this post previously:
https://blog.codeship.com/the-json-api-spec/

Probably needs headers
https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec#requesting-a-json-response

CORS
https://www.digitalocean.com/community/tutorials/how-to-setup-ruby-on-rails-with-postgres


