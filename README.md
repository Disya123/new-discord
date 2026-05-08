# NDiscord

Discord-like messenger with end-to-end encryption, screen sharing, and AI noise suppression.

## Tech Stack

- **Backend:** Python 3.12 + FastAPI + SQLAlchemy + PostgreSQL + Redis
- **Frontend:** Flutter (Dart) - iOS, Android, Windows, Web
- **Encryption:** Signal Protocol (E2EE)
- **Voice/Video:** WebRTC
- **Noise Suppression:** RNNoise (native FFI)

## Quick Start

### 1. Start infrastructure

```bash
docker-compose up -d postgres redis
```

### 2. Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

### 3. Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### Full Docker stack

```bash
docker-compose up --build
```

## Architecture

```
Client (Flutter)  ←→  WebSocket  ←→  FastAPI Backend  ←→  PostgreSQL
      ↓                     ↓              ↓
   WebRTC              Redis Pub/Sub    Alembic
   RNNoise
   Signal Protocol E2EE
```

## Features

- **Servers** — create/join servers with invite codes
- **Channels** — text and voice channels per server
- **Direct Messages** — private 1-on-1 conversations
- **E2EE** — Signal Protocol encryption (server never sees plaintext)
- **Voice Chat** — WebRTC-based voice channels
- **Screen Sharing** — share your screen via WebRTC
- **Noise Suppression** — RNNoise AI-based background noise removal
- **Typing Indicators** — see who is typing
- **Presence** — online/offline status
- **Replies** — reply to specific messages

## Project Structure

```
NDiscord/
├── backend/          # Python FastAPI server
│   ├── app/
│   │   ├── api/      # REST endpoints
│   │   ├── models/   # SQLAlchemy models
│   │   ├── schemas/  # Pydantic schemas
│   │   ├── security/ # JWT, auth
│   │   └── ws/       # WebSocket handlers
│   └── alembic/      # DB migrations
├── frontend/         # Flutter app
│   └── lib/
│       ├── models/   # Dart data models
│       ├── services/ # API, WS, WebRTC, E2EE
│       ├── providers/# Riverpod state
│       ├── screens/  # UI screens
│       └── widgets/  # Reusable widgets
├── shared/           # Shared protocol definitions
└── docker-compose.yml
```

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Key variables:
- `DATABASE_URL` — PostgreSQL connection string
- `REDIS_URL` — Redis connection string
- `JWT_SECRET` — Secret key for JWT tokens
- `TURN_*` — TURN server credentials for WebRTC
