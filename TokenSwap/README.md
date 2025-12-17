# Token Swap Service

This is a Sinatra-based Ruby service that handles OAuth token swapping for the Spotify iOS SDK.

## Running with Docker

### Using Docker Compose (Recommended)

The easiest way to run the server:

```bash
docker-compose up
```

To stop the server:

```bash
docker-compose down
```

To rebuild after changes:

```bash
docker-compose up --build
```

## Configuration

**⚠️ IMPORTANT**: Before deploying to production, you must configure your credentials.

### Using Environment Variables (Recommended)

1. Copy the example environment file:

```bash
cp env.example .env
```

2. Edit `.env` and update the values:

- `CLIENT_ID` - Your Spotify client ID
- `CLIENT_SECRET` - Your Spotify client secret
- `ENCRYPTION_SECRET` - A secure random string (generate with: `openssl rand -base64 32`)
- `CLIENT_CALLBACK_URL` - Your app's callback URL

The `.env` file is automatically loaded by Docker Compose and ignored by git for security.

## Endpoints

The server exposes two endpoints:

- `POST /swap` - Exchange an authorization code for access tokens
- `POST /refresh` - Refresh an access token using a refresh token

