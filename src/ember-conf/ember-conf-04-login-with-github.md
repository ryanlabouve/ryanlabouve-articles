# Login with Github

This is going to be an intense article!

Here's what we'll tackle

1. We can grab an authorization token from github

2. We use our Github authorization token to create a new user

3. We use our Github authorization token to login as an existing user

4. We can see current user profile only we are authorized

5. We can logout as current user

6. We create a booking with our current user

---

## 1. Login with Github

Web application flow:

1. Users are redirect to request their GitHub identity

2. Users are redirected back to your site by GitHub

3. Your app accesses the API with the user's access token

![https://raw.githubusercontent.com/simplabs/ember-simple-auth/master/guides/assets/esa-initial-flow.txt.png](https://raw.githubusercontent.com/simplabs/ember-simple-auth/master/guides/assets/esa-initial-flow.txt.png)

Here's how to do it:

### Create a new Github Oauth Application on Github

- Visit https://github.com/settings/applications/new

Homepage & Callback URL: http://localhost:4586

Client ID
48ba376cd67f88fb8b71
Client Secret
d280bec1a07570db4c8d9c982400a7a2e917a6da

- https://github.com/settings/applications/1000004

"OAuth is officially an authorization protocol, but is commonly used also for authentication"

The question... do we use 2 authorizers? We don't care about the Github Stuff after we have the original key

Maybe we just use it as a first step.

// TODO: update to the HTTP Cookie approach
// TODO: would be nice to drive this with tests

```bash
ember install ember-simple-auth
ember install torii
```

```diff
var ENV = {
  ...
+  torii: {
+    sessionServiceName: 'session',
+    providers: {
+      'github-oauth2': {
+        apiKey: 'YOUR_API_KEY',
+        redirectUri: 'http://localhost:4200',
+        scope: 'repo user'
+      }
+    }
+  }
};
```

```bash
ember g controller application
```

```js
// app/controllers/application.js
import Controller from "@ember/controller";
import { inject as service } from "@ember/service";
import config from "super-rentals/config/environment";

export default Controller.extend({
  session: service(),
  config: config.torii.providers["github-oauth2"]
});
```

```bash
ember g authenticator torii
```

```
ember g route application
```

// TODO: do we need to do something special for unauthenticated route mixin?

```
ember g authenticator torii
```

```js
import ToriiAuthenticator from 'ember-simple-auth/authenticators/torii';
import {inject as service} from '@ember/service';

export default ToriiAuthenticator.extend({
  torii: service(),
```

```js
// app/torii-providers/github.js

import GitHubOAuth2Provider from "torii/providers/github-oauth2";

export default GitHubOAuth2Provider.extend({
  fetch(data) {
    return data;
  }
});
```

```diff
// app/controllers/application.js
+  actions: {
+    login() {
+      this.get('session').authenticate('authenticator:torii', 'github');
+    }
+  }
```

```hbs
<button onclick={{action "login"}}>Log in to GitHub</button>
```

HERE WE HAVE THE AUTHORIZATION CODE

"We've now established the mechanism to obtain an authorization code from GitHub. This doesn't authorize us fully to use the GitHub APIs, although ember-simple-auth considers us authenticated at this point, but we can add some information to our application template that at least verifies things work so far" https://github.com/simplabs/ember-simple-auth/blob/master/guides/auth-torii-with-github.md

"We need to have a token exchange service, a service that takes an authorization code and returns an access token"

```diff
        'github-oauth2': {
          apiKey: '48ba376cd67f88fb8b71',
          redirectUri: 'http://localhost:4586',
          scope: 'repo user',
+         tokenExchangeUri: 'http://localhost:3000/api/tokens'
```

TODO: Fig this out. Probably need an oauth.html

```
[Torii] Using an OAuth redirect that loads your Ember App is deprecated and will be
              removed in a future release, as doing so is a potential security vulnerability.
              Hide this message by setting `allowUnsafeRedirect: true` in your Torii configuration.
```

```
ember install ember-fetch
```

Rails part
https://auth0.com/docs/api-auth/why-use-access-tokens-to-secure-apis

https://www.pluralsight.com/guides/token-based-authentication-with-ruby-on-rails-5-api

rails g model User email:string email:string password_digest:string username:string github_username:string github_id:integer github_email:string

gem 'bcrypt', '~> 3.1.7'

https://apidock.com/rails/v4.0.2/ActiveModel/SecurePassword/ClassMethods/has_secure_password

https://github.com/settings/applications/1000004

```js
  authenticate() {
    // const ajax = this.get('ajax');
    const tokenExchangeUri = config.torii.providers['github-oauth2'].tokenExchangeUri;

    // TODO: move this to fetch or something
    return this._super(...arguments).then((data) => {
      let body = JSON.stringify(data);

      let headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
      }

      let params = {
        method: 'POST',
        headers,
        body
      };

      return fetch(tokenExchangeUri, params).then( (response) => {
        return response.json().then(json => {
          return {
            access_token: json.access_token,
            provider: json.provider,
            email: json.email
          };
        }).catch(error => console.error(error));
      }).catch(error => console.error(error));
    }).catch(error => console.error(error));
  }
```

```rb
module Api
  clggass TokensController < ApplicationController
    def create
      # {"authorizationCode"=>"43e1931a5722942bc948", "provider"=>"github", "redirectUri"=>"http://localhost:4586"}
      @token_params = token_params

      @client_id = "48ba376cd67f88fb8b71"
      @client_secret = "d280bec1a07570db4c8d9c982400a7a2e917a6da"
      @code = @token_params[:authorizationCode]

      @headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }

      @query = {
        client_id: @client_id,
        client_secret: @client_secret,
        code: @code
      }

      @auth_url = "https://github.com/login/oauth/access_token"
      @github_auth_request = HTTParty.post(
        @auth_url,
        headers: @headers,
        query: @query
      )

      @github_access_token = @github_auth_request["access_token"]
      # TODO: should thorw up here if token is not there

      @github_user_request_headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github.v3+json',
        "Authorization": "token #{@github_access_token}",
        'User-Agent': 'ryanlabouve'
      }
      @user_url = "https://api.github.com/user"
      @github_user_request = HTTParty.get(
        @user_url,
        headers: @github_user_request_headers
      )

      @user = User.where(github_id: @github_user_request["id"]).first

      if !@user.present?
        @access_token = SecureRandom.urlsafe_base64(nil, false)

        @user = User.create({
          email: @github_user_request["email"],
          username: @github_user_request["login"],
          github_username: @github_user_request["login"],
          github_id: @github_user_request["id"],
          github_email: @github_user_request["email"],
          access_token: @access_token,
          avatar_url: @github_user_request["avatar_url"],
          password: @access_token
        }).save!

      end

      render json: {
        email: @user.email,
        access_token: @user.access_token,
        provider: "github"
      }
    end

    private

    def token_params
      params.permit(:authorizationCode, :provider, :redirectUri)
    end
  end
end
```

https://www.pluralsight.com/guides/token-based-authentication-with-ruby-on-rails-5-api

HEre is where we finished this: https://github.com/simplabs/ember-simple-auth/blob/master/guides/auth-torii-with-github.md

---

### Current User

```
ember g model user
```

```
ember g service current-user
```

```
ember g adapter authorized
```

```js
import ApplicationAdapter from "./application";
import DataAdapterMixin from "ember-simple-auth/mixins/data-adapter-mixin";

export default ApplicationAdapter.extend(DataAdapterMixin, {
  session: service(),
  authorize(xhr) {
    let { access_token } = this.get("session.data.authenticated");
    if (isPresent(access_token)) {
      xhr.setRequestHeader("Authorization", `token ${access_token}`);
    }
  }
});
```

https://github.com/simplabs/ember-simple-auth#deprecation-of-authorizers

```js
import Service from "@ember/service";
import { inject as service } from "@ember/service";

export default Service.extend({
  store: service(),
  session: service(),

  user: null,

  load() {
    let email = this.get("session.data.authenticated.email");

    if (email) {
      return this.get("store")
        .query("user", {
          email
        })
        .then(user => {
          // assert if the lenght > 1
          this.set("user", user.get("firstObject"));
        })
        .catch(error => {
          console.log(error);
        });
    } else {
      return Ember.RSVP.resolve();
    }
  }
});
```

### Returning current user from rails

```rb
module Api
  class UsersController < ApplicationController
    def index
      @current_user = current_user
      @params = user_params

      if @current_user.present? && @current_user.email == @params[:email]
        render json: UserSerializer.new([@current_user]).serialized_json
      else
        render json: {
          errors:[
            status: "401",
            detail: 'Unauthorized'
          ]
        }, status: :unauthorized
      end
    end

    private

    def user_params
      params.permit(:email)
    end
  end
end
```

### Creating a booking as a user

https://github.com/ryanlabouve/super-rentals-api/commit/905cecb5a0ea5dfe511a041e97403e5905a07516

https://github.com/ryanlabouve/super-rentals-burner/pull/2/commits/5be382c9dcb7bc5ac9134c3c10fa903212a5877e
