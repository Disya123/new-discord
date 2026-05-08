# NDiscord

Discord-like messenger with end-to-end encryption, screen sharing, and AI noise suppression.

## Tech Stack

- **Backend:** Python 3.12 + FastAPI + SQLAlchemy + PostgreSQL + Redis
- **Frontend:** Flutter (Dart) Web — served via nginx
- **Encryption:** Signal Protocol (E2EE)
- **Voice/Video:** WebRTC
- **Noise Suppression:** RNNoise (native FFI)

---

## Deploy via Portainer

### 1. Подготовка .env

Создайте файл `.env` в корне репозитория (или задайте переменные в Portainer):

```env
POSTGRES_PASSWORD=your_strong_db_password
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
SERVER_IP=your.server.ip
WEB_PORT=8080
TURN_USERNAME=turnuser
TURN_PASSWORD=turnpassword
```

### 2. Portainer — Add Stack

1. Откройте Portainer → **Stacks** → **Add Stack**
2. Выберите **Repository**
3. Заполните:
   - **Repository URL:** `https://github.com/Disya123/new-discord`
   - **Compose path:** `docker-compose.yml`
4. В секции **Environment variables** добавьте все переменные из `.env`
5. Нажмите **Deploy the stack**

Portainer сам склонирует репозиторий, собмёт образы и запустит контейнеры.

### 3. Проверка

После деплоя (~3-5 минут на сборку):

| Сервис | URL |
|--------|-----|
| Frontend | `http://your.server.ip:8080` |
| Backend API | `http://your.server.ip:8080/api/v1/docs` |
| WebSocket | `ws://your.server.ip:8080/ws` |

### 4. Firewall

Откройте порты на сервере:

```bash
# Web UI
sudo ufw allow 8080/tcp

# TURN server (для WebRTC)
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 49152:65535/udp
```

---

## Local Development

### Docker (все сразу)

```bash
cp .env.example .env
# Отредактируйте .env если нужно
docker-compose up --build
```

Frontend: http://localhost:8080
Backend API: http://localhost:8000/docs

### Backend отдельно

```bash
cd backend
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend отдельно

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## Architecture

```
┌─────────────┐     ┌──────────┐     ┌──────────────┐     ┌────────────┐
│   Browser   │────▶│  nginx   │────▶│   FastAPI    │────▶│ PostgreSQL │
│  (Flutter)  │     │  :8080   │     │   :8000      │     │   :5432    │
└─────────────┘     └──────────┘     └──────────────┘     └────────────┘
                         │                   │
                    Static files        Redis :6379
                    + reverse proxy     (Pub/Sub, cache)
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

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | DB password | `ndiscord_secret` |
| `JWT_SECRET` | JWT signing key | `change-me-...` |
| `SERVER_IP` | Public server IP | `localhost` |
| `WEB_PORT` | Frontend port | `8080` |
| `TURN_URL` | STUN/TURN URL | `stun:stun.l.google.com:19302` |
| `TURN_USERNAME` | TURN user | `turnuser` |
| `TURN_PASSWORD` | TURN password | `turnpassword` |
