# Metabotbot

Prompt: I have X silly chatbots I want to make, I don't want to pay x\*7/mo to host them on Heroku.

I want to pay 5 dollars a month or less.

Mandatories

* 0 manual confiugration for new bots (i.e. Heroku style ease)
* Bots can all run on CI and deploy to _something_ like any other project (i.e. Heroku pipelines)
* I have _some monitoring_ to know if my bots are running (i.e. Heroku metrics)

Nice to haves

* ??

## Nieve approach

Before doing _ANY_ research, I'm going to hypothesize a possible route.

* Kilobot sets up a webhook on any bot repos
* When a new change is merged into master, the change are built, the bot is spun up in a seperate service, traffic is moved over to new service, old service is shut down.
* OPEN: how is bot spun up?
* https://github.com/litaio/docker-lita ?
* We use _some orchestration layer_ to manage the running of all the things that we can use to hopefully get stats / tools around running/booting services
* OPEN QUESTION: Are there any shared resoruces? Are there any resources that are run specifically for a single repo (e.g. 1 redis instance, but multiple

Launch Rails API & Ember app dashboard

* Setup auth/auth with github
* Allow user to find "lita repos"
* Allow user to add "lita repos" to killobot

Kilobot dashboard

* Login with Github
*
*
*
*
*

All the social logins with github+devize
https://scotch.io/tutorials/integrating-social-login-in-a-ruby-on-rails-application

on top of devise again https://remimercier.com/omniauth-github-rails-app-with-devise/

Maybe some insight here maybe not
https://learn.co/lessons/rails-blog-omniauth

Non devise. Let's start here
