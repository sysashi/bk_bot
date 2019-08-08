## Deploying
### Required env variables

  * `FACEBOOK_APP_ID`
  * `FACEBOOK_APP_SECRET`
  * `FACEBOOK_PAGE_ACCESS_TOKE`
  * `FACEBOOK_WEBHOOK_VERIFICATION_TOKEN`
  * `GOODREADS_KEY`

### Steps

This code is currently deployed via [dokku](https://github.com/dokku/dokku)
There is no storage requirements so basically any approach would work.

Just set your webhook url as `https://<your-host>/facebook/webhook`,
use verification token to verify your url.

App also expects these webhook events
to be set: `messages, messaging_postbacks, messaging_referrals`.

## Testing

Run `mix test` from the root of the project.

There is just generic test that ensures _happy path_ of the conversation flow.

If I were to implement proper api clients for 3rd party apis, they would be
proper elixir behaviours
(that are also nice to test with [Mox](https://github.com/plataformatec/mox)).

## Couple words

**Note:**  this is a stripped down phoenix app which missing integration with ibm watson api, 
but has more sophisticated ai analysis /s

  * Making facebook client play nicely with api takes a bit of time
  * Same goes for registering for all 3rd parties / figuring out testing
      environment, etc.
  * Unfortunately I could not find endpoint that returns reviews in text format
      on Goodreads' website. So there is no semantic analysis.

