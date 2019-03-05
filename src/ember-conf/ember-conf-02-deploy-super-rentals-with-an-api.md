
## Hooking up super-rentals to our Rails API and deploying it.



Shameless plug:
```
ember install ember-cli-randoport
```

TODO: Move the mirage stuff on super rentals master here.

Eventually we can talk about environment etc... but not that big of a deal

```js
// /app/adapters/application.js

import DS from 'ember-data';
import config from '../config/environment';

let {host} = config;

export default DS.JSONAPIAdapter.extend({
  namespace: 'api',
  host,
});
```


`ENV.host = ''`


```js
  if (process.env.ENABLE_MIRAGE) {
    ENV['ember-cli-mirage'] = {
      enabled: true,
    };
  } else {
    ENV['ember-cli-mirage'] = {
      enabled: false,
    };
  }
  ```


```js
  if (environment === 'development') {
    if (ENV['ember-cli-mirage'].enabled) {
      ENV.host = '';
    } else {
      ENV.host = 'http://localhost:3000';
    }
```


```js
// mirage/config.js

export default function() {
  this.namespace = '/api';
  this.passthrough('https://api.mapbox.com/**');

  this.get('/rentals', function(db, request) {
    let city = request.queryParams.city;
    if (city !== undefined) {
      return db.rentals.all().filter(rental => {
        return rental.attrs.city.toLowerCase().indexOf(city) > -1;
      });
    } else {
      return db.rentals.all();
    }
  });

  // Find and return the provided rental from our rental list above
  this.get('/rentals/:id', function(db, request) {
    return {data: rentals.find(rental => request.params.id === rental.id)};
  });
}
```

```js
// package.json
"scripts": {
    // ...
    "start:mirage": "ENABLE_MIRAGE=true ember serve"
}
```


`npm run start:mirage`