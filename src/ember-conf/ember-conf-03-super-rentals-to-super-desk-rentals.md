Here the goal is to move the _super rentals_ app to be the start of _super desk rentals_.



super rentals
![https://com-ryanlabouve-blog.s3.amazonaws.com/ember-conf/super-rentals-flow.png](https://com-ryanlabouve-blog.s3.amazonaws.com/ember-conf/super-rentals-flow.png)
https://www.lucidchart.com/documents/edit/009cd991-7942-4a22-9479-1f0a53ade7fb/1

super desk rentals
![https://com-ryanlabouve-blog.s3.amazonaws.com/ember-conf/super-desk-rentals.png](https://com-ryanlabouve-blog.s3.amazonaws.com/ember-conf/super-desk-rentals.png)
https://www.lucidchart.com/documents/edit/009cd991-7942-4a22-9479-1f0a53ade7fb/2

Make enough changes to help the next article be very focused on "sign-in with Github"

## The Front End

### A few cosmetic tweaks

![https://com-ryanlabouve-blog.s3.amazonaws.com/ember-conf/superdeskrentals.png](https://com-ryanlabouve-blog.s3.amazonaws.com/ember-conf/superdeskrentals.png)

### Story 1: A booking pass can be created from a rental

```js
  test('should be able to book a rental', async function(assert) {
    // Visit rental
    // Select a date
    // Click book
    // See new booking
  });
```

Fill in what we need from pervious tests.

```js
  test('should be able to book a rental', async function(assert) {
    server.create('rental', {
      title: 'StarSpace46',
      city: 'Oklahoma City',
    });

    await visit('/rentals');
    await click(`[href='/rentals/1']`);

    await click('[data-test-book-rental]')
    await pauseTest();
    // Select a date
    // Click book
    // See new booking
  });
```

`Promise rejected during "should be able to book a rental": Element not found when calling `click('[data-test-book-rental]')`.`

```hbs
<div class="jumbo show-listing">
  <h3 class="title">Book this office today!</h3>
  <div class="content">
    <button data-test-book-rental>Book Now</button>
  </div>
</div>
```

Let's test to the next fail

```js
  test('should be able to book a rental', async function(assert) {
    server.create('rental', {
      title: 'StarSpace46',
      city: 'Oklahoma City',
    });

    await visit('/rentals');
    await click(`[href='/rentals/1']`);

    // select date
    await click('[data-test-book-rental]');
    assert.equal(server.db.bookings.length, 1);
  });
```

### Wire up the botton

`ember g controller rentals/show`

```hbs
{{! templates/renatls/show.hbs}}
<button onclick={{action 'bookRental' this.model}} data-test-book-rental>Book Now</button>
```

```js
// /controllers/rentals/show.js
import Controller from '@ember/controller';

export default Controller.exGtend({
  actions: {
    bookRental(rental, e) {
      e.preventDefault();

      return this.store.createRecord('booking', {
        rental
      }).save();
    }
  }
});

```

error now

`Error: No model was found for 'booking'`

### Making some bookings

`ember g model booking`

```js
// app/models/booking.js
import DS from 'ember-data';

export default DS.Model.extend({
  rental: DS.belongsTo()
});
```

`Error: Mirage: Your Ember app tried to POST '/api/bookings',`

```js
// mirage/config/js
+   this.post('/bookings');
```

```js
    assert.equal(
      this.element.querySelectorAll('[data-test-booking]').length,
      1,
      'We should see a booking',
    );
```


```
We should see a booking@ 6404 ms
Expected: 	

1

Result: 	

0
```

asdf

```js
import DS from 'ember-data';

export default DS.Model.extend({
  title: DS.attr(),
  owner: DS.attr(),
  city: DS.attr(),
  category: DS.attr(),
  image: DS.attr(),
  bedrooms: DS.attr(),
  description: DS.attr(),

+  bookings: DS.hasMany()
});
```

And we are green.

We could add some date stuff here

-------

Commit and switch to API. COuld have added a date things.

### API stories,

```
POST /booking
```

and 

```
GET /rentals/1?included=bookings includes booking relationships
```

```rb
  it "includes booking relationship information" do
    oklahoma_city_rental = create(:rental, {
      city: "Oklahoma City"
    })

    create(:booking, {
      rental: oklahoma_city_rental
    })
  end
```

```rb
FactoryBot.define do
  factory :booking do
  end
end
```

`uninitialized constant Booking`

`rails g model Booking`

Fill out the migration

```rb
class CreateBookings < ActiveRecord::Migration[5.2]
  def change
    create_table :bookings do |t|
      t.references :rental
      t.date :date
      t.timestamps
    end
  end
end
```

Add relationship to booking

```rb
class Booking < ApplicationRecord
  belongs_to :rental
end
```

relationsihps nil

```rb
expect(relationships).not_to be_nil
expect(relationships.dig('bookings').length).to eq(1)
expect(relationships.dig('bookings', 'data')[0].dig("id").to_i).to eq(booking.id)
```

add relationship on serializer

```diff
class RentalSerializer
  include FastJsonapi::ObjectSerializer
+ has_many :bookings
  attributes :title, :owner, :city, :category, :bedrooms, :description, :image
end
```

```
 NoMethodError:
       undefined method `booking_ids' for #<Rental:0x00007fa0bf293030>
```

Adds bookings relationship to rentals

```rb
class Rental < ApplicationRecord
  has_many :bookings
end
```

GREEEEEN.

Now let's get them links

```diff
...
expect(relationships.dig('bookings').length).to eq(1)
expect(relationships.dig('bookings', 'data')[0].dig("id").to_i).to eq(booking.id)

+bookings_links = data.dig("links", "bookings")
+expect(bookings_links.length).to eq(1)
+expect(bookings_links[0].dig("id").to_i).to eq(booking.id)
+expect(bookings_links[0].dig("rental_id")).to eq(booking.rental.id)
```

```diff
class RentalSerializer
  ...
+ link :bookings
  ...
end
```

Adds booking serializer

```rb
class BookingSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :date
end
```


NOWWWWW let's create the booking.

```rb
require "spec_helper"
require "rails_helper"

describe "/POST bookings", type: :request do
  it "creates a new booking" do
    expect(Booking.all.count).to eq(0)

    post "/bookings"

    expect(Booking.all.count).to eq(1)

    # expect(first_rental.dig("attributes", "title")).to eq(rentals.first.title)
    # expect(first_rental.dig("attributes", "owner")).to eq(rentals.first.owner)
    # expect(first_rental.dig("attributes", "city")).to eq(rentals.first.city)
    # expect(first_rental.dig("attributes", "category")).to eq(rentals.first.category)
    # expect(first_rental.dig("attributes", "bedrooms")).to eq(rentals.first.bedrooms)
    # expect(first_rental.dig("attributes", "description")).to eq(rentals.first.description)
  end
end
```

```
  1) /POST bookings creates a new booking
     Failure/Error: post "/bookings"
     
     ActionController::RoutingError:
       No route matches [POST] "/bookings"
```

```diff
+    resources :bookings, only: [:create]
```

```bash
  1) /POST bookings creates a new booking
     Failure/Error: post "/api/bookings"
     
     ActionController::RoutingError:
       uninitialized constant Api::BookingsController
```

Create controller
```rb
module Api
  class BookingsController < ApplicationController
  end
end
```

```
1) /POST bookings creates a new booking
     Failure/Error: post "/api/bookings"
     
     AbstractController::ActionNotFound:
       The action 'create' could not be found for Api::BookingsController
```

create action
```diff
  class BookingsController < ApplicationController
+   def create
+   end
  end
```

```
 1) /POST bookings creates a new booking
     Failure/Error: expect(Booking.all.count).to eq(1)
     
       expected: 1
            got: 0
```

Do the actual create

```rb
require "spec_helper"
require "rails_helper"

describe "/POST bookings", type: :request do
  it "creates a new booking" do
    rental = create(:rental)
    
    expect(Booking.all.count).to eq(0)

    post "/api/bookings", {
      params: {
        data: {
          type: 'bookings',
          attributes: {},
          relationships: {
            rental: {
              data: {
                id: rental.id
              }
            }
          }
        }
      },
      headers: {}
    }

    expect(response).to have_http_status(:created)
    expect(response).to probably_be_json_api

    expect(Booking.all.count).to eq(1)

    # expect(first_rental.dig("attributes", "title")).to eq(rentals.first.title)
    # expect(first_rental.dig("attributes", "owner")).to eq(rentals.first.owner)
    # expect(first_rental.dig("attributes", "city")).to eq(rentals.first.city)
    # expect(first_rental.dig("attributes", "category")).to eq(rentals.first.category)
    # expect(first_rental.dig("attributes", "bedrooms")).to eq(rentals.first.bedrooms)
    # expect(first_rental.dig("attributes", "description")).to eq(rentals.first.description)
  end
end
```

And implement to passing

```rb
module Api
  class BookingsController < ApplicationController
    def create
      # look at codeship blog
      @rental = rental
      @booking = Booking.create(rental: @rental)

      if @booking.save!
        render status: :created, json: BookingSerializer.new(@booking).serialized_json
      else
        "render an error"
      end
    end

    private

    def rental
      Rental.find(relationship_params[:id])
    end

    def logged_session_params
      # TODO: do something better here
      params.require(:data).require(:attributes).permit()
    end

    def relationship_params
      params.require(:data).require(:relationships).require(:rental).require(:data).permit(:id)
    end

    # def rental_params
  end
end
```

Flesh out tests
```diff
    expect(Booking.all.count).to eq(1)

+    body = JSON.parse(response.body)
+    data = body.dig("data")
+
+    attributes = data.dig("attributes")
+    relationships = data.dig("relationships")
+
+    created_booking = Booking.last
+
+    # does this act poorly when paralell tests?
+    expect(data.dig("id").to_i).to eq(created_booking.id)
+    expect(data.dig("type")).to eq("booking")
+    expect(relationships.dig("rental", "data", "id").to_i).to eq(rental.id)
```

( Maybe add one more spec to cover if there is an error)

## FE and BE reunited song

Need to add this somewheres earlier
```rb
    config.before_initialize do
      api_mime_types = %w[
        application/vnd.api+json
        text/x-json
        application/json
      ]
      Mime::Type.register 'application/vnd.api+json', :json, api_mime_types
    end
```


* Can we create a booking?
* Can we see bookings that have already been created?

Firing off N+1 style async requets.

Need to update spec... shows "links" instead of "included"

```diff
+    # Make sure we include the booking informations
+    included = body.dig("included")
+    expect(included.length).to eq(1)
+    expect(included[0].dig("id").to_i).to eq(booking.id)
```

# TODO: maybe refactor this

```rb
module Api
  class RentalsController < ApplicationController
    def index
      @rentals = Rental

      if search_terms[:city].present?
        @rentals = @rentals.where("lower(city) LIKE lower(?)", "%#{search_terms[:city]}%")
      end
      @rentals = @rentals.all

      options = {}
      options[:include] = %i[
        bookings
      ]
      render json: RentalSerializer.new(@rentals, options).serialized_json
    end

    def show
      @rental = rental

      options = {}
      options[:include] = %i[
        bookings
      ]
      render json: RentalSerializer.new(@rental, options).serialized_json
    end

    private

    def rental
      Rental.find(params[:id])
    end

    def search_terms
      params.permit(:city)
    end
  end
end
```

Now we have an app where we can make bookings! Next, Let's add the imfamous "Login with Github" button