# 1Password CLI — secret management

**Access your vault from the terminal, without exposing secrets in files.**

The 1Password CLI (`op`) lets scripts and tools pull secrets directly
from your vault at runtime. No `.env` files with real credentials. No
secrets accidentally committed to git.

## Authenticate first

If you haven't already, sign in:

  op signin

You'll be prompted for your vault password. After that, secrets are
available for the session.

## Useful commands

  op item list                     — browse your vault
  op item get "My API Key"         — view an item
  op read "op://vault/item/field"  — read a single field

## In scripts and .env files

Reference secrets with op:// URIs:

  export STRIPE_SECRET=$(op read "op://Development/Stripe/secret_key")

Or use `op run` to inject secrets as environment variables:

  op run --env-file=.env.op -- npm start

Your `.env.op` file contains op:// references instead of real values —
safe to commit.

## SSH agent

Your SSH keys are stored in 1Password and served via the agent socket:

  ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock

This is already configured in `~/.ssh/config`. Your private keys never
touch disk in plaintext.

## GPG keys

GPG signing keys are also stored in 1Password. If you set up git commit
signing, it reads the key from the vault automatically.
