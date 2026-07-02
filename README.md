# AI Pet Health Assistant Platform 🐾

> Intelligent veterinary support platform — AI-powered symptom analysis, emergency detection, pet health monitoring, and personalized recommendations.

## Architecture Overview

```
┌────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                      │
│           Riverpod | GoRouter | Dio | Freezed              │
└──────────────────────────┬─────────────────────────────────┘
                           │ HTTPS / WSS
┌──────────────────────────▼─────────────────────────────────┐
│                  NestJS API Gateway (AWS ECS)               │
│        JWT Auth | RBAC | Throttling | Swagger Docs          │
└──┬───────────────┬──────────────────┬──────────────────┬────┘
   │               │                  │                  │
┌──▼──┐     ┌──────▼──────┐    ┌─────▼──────┐    ┌─────▼────┐
│Auth │     │   CRUD      │    │  AI Router │    │ Payments │
│JWT  │     │ Users/Pets  │    │  (NestJS)  │    │ (Stripe) │
└──┬──┘     └──────┬──────┘    └──────┬──────┘    └──────────┘
   │               │                  │
   │         ┌─────▼──────┐    ┌──────▼──────────────────────┐
   │         │ PostgreSQL │    │ FastAPI AI Service (On-Prem) │
   │         │  (RDS)     │    │ ─────────────────────────── │
   │         │  +pgvector │    │ ┌────────────────────────┐  │
   │         └────────────┘    │ │      AI Router          │  │
   │                           │ │  ┌────┬────┬────┬────┐ │  │
   │         ┌────────────┐   │ │  │Qwen│Qwen│Qwen│BGE │ │  │
   │         │   Redis    │   │ │  │1.5B│ 7B │ VL │ M3 │ │  │
   │         │   (Cache)  │   │ │  └────┴────┴────┴────┘ │  │
   │         └────────────┘   │ └────────────────────────┘  │
   │                          │   Fallback: Longcat/OpenAI  │
   │                          └─────────────────────────────┘
```

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile** | Flutter + Riverpod | Cross-platform iOS/Android |
| **Backend** | NestJS + TypeORM | API Gateway, Business Logic |
| **AI Service** | FastAPI (Python) | Local LLM inference |
| **Local Models** | Qwen2.5 7B/1.5B + BGE-M3 | CPU-optimized GGUF quantized |
| **Cloud AI** | Longcat (Meituan) | Fallback provider |
| **Database** | PostgreSQL + pgvector | App data + RAG embeddings |
| **Cache** | Redis | Session cache, rate limiting |
| **Infrastructure** | AWS ECS / On-Prem Docker | Container orchestration |
| **Monitoring** | Prometheus + Grafana | Metrics & observability |

## Project Structure

```
pet-health-assistant/
├── pet-app/                 # Flutter mobile application
│   └── lib/
│       ├── core/            # Constants, theme, network, router
│       ├── shared/          # Reusable widgets, shared providers
│       └── features/        # Feature modules (auth, pet, symptom...)
├── pet-backend/             # NestJS API Gateway
│   └── src/
│       ├── modules/         # Feature modules
│       │   ├── auth/        # JWT authentication
│       │   ├── users/       # User management
│       │   ├── pets/        # Pet CRUD
│       │   ├── symptoms/    # Symptom records + AI integration
│       │   ├── emergency/   # Emergency detection
│       │   ├── recommendations/ # Food/product recommendations
│       │   ├── veterinary/  # Vet directory + appointments
│       │   ├── notifications/ # Push notifications
│       │   ├── subscriptions/ # Stripe billing
│       │   └── admin/       # Admin dashboard
│       └── common/          # Guards, decorators, interceptors
├── pet-ai-service/          # FastAPI AI Service (On-Premise)
│   └── app/
│       ├── clients/         # Ollama, Cloud AI, Redis clients
│       ├── services/        # AI Router, symptom analyzer, emergency
│       ├── models/          # Pydantic request/response schemas
│       ├── prompts/         # System prompts
│       └── utils/           # Parsers, dependencies
├── pet-infra/               # Infrastructure & DevOps
│   ├── docker/              # Docker Compose, init SQL
│   ├── monitoring/          # Prometheus, Grafana configs
│   └── scripts/             # Setup scripts, knowledge base seeder
└── README.md
```

## Quick Start

### Prerequisites
- Flutter SDK 3.2+
- Node.js 20+
- Python 3.12+
- Docker & Docker Compose
- Ollama (for local AI)

### 1. On-Premise AI Service (FastAPI + Qwen)

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull Qwen models (CPU-optimized GGUF)
ollama pull qwen2.5:7b-q4_K_M
ollama pull qwen2.5:1.5b-q4_K_M
ollama pull bge-m3:latest

# Start the AI service
cd pet-ai-service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Test it
curl http://localhost:8000/health
curl -X POST http://localhost:8000/v1/symptoms/analyze \
  -H "X-API-Key: dev-internal-key" \
  -H "Content-Type: application/json" \
  -d '{"text":"My dog has a mild cough and runny nose","pet_species":"dog","pet_age":3}'
```

### 2. NestJS Backend

```bash
cd pet-backend
npm install
npm run start:dev
```

### 3. Flutter App

```bash
cd pet-app
flutter pub get
flutter run
```

### 4. Full Stack (Docker Compose)

```bash
docker-compose -f pet-infra/docker/docker-compose.yml up -d
```

## API Endpoints

### NestJS Gateway (Cloud)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1/auth/register` | User registration |
| POST | `/v1/auth/login` | User login (returns JWT) |
| GET | `/v1/users/me` | Current user profile |
| POST | `/v1/pets` | Create pet |
| GET | `/v1/pets` | List user's pets |
| POST | `/v1/symptoms/analyze` | Analyze symptoms (calls AI service) |
| POST | `/v1/emergency/check` | Emergency triage |
| POST | `/v1/recommendations/food` | Food recommendations |

### FastAPI AI Service (Local/On-Premise)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/v1/health` | Service health + model status |
| POST | `/v1/symptoms/analyze` | Symptom text analysis (Qwen2.5) |
| POST | `/v1/symptoms/analyze-image` | Pet photo analysis (Qwen2.5-VL) |
| POST | `/v1/emergency/check` | Emergency detection |
| POST | `/v1/recommendations/food` | Nutrition recommendations |
| POST | `/v1/knowledge/query` | RAG knowledge base query |

## AI Providers

The platform supports **three AI providers** with automatic fallback:

| Provider | Type | Model | Latency | Cost |
|----------|------|-------|---------|------|
| **Qwen2.5 (Local)** | Open-source | 7B Q4 GGUF | ~1.5s first token (CPU) | Free |
| **Longcat** | Cloud API | LongCat-Flash-Chat | ~300ms | ~$0.10/M tokens |
| **OpenAI** | Cloud API | GPT-4o-mini | ~500ms | ~$0.15/M tokens |

The AI Router in FastAPI automatically:
1. Tries **local Qwen** first (low latency, zero cost)
2. Falls back to **Longcat** if local is down
3. Falls back to **OpenAI** if Longcat is down

Users can toggle between Local/Cloud in **Settings > AI Provider**.

## Freemium Model

| Feature | Free | Premium ($9.99/mo) | Pro ($19.99/mo) |
|---------|------|--------------------|-----------------|
| Symptom Checker | 3/month | Unlimited | Unlimited |
| Pet Profiles | 1 pet | 5 pets | Unlimited |
| Emergency Detection | ✅ | ✅ | ✅ |
| Health Dashboard | Basic | Advanced | Advanced + Export |
| Food Recommendations | ❌ | ✅ | ✅ + Discounts |
| Telehealth Booking | ❌ | ❌ | ✅ |

## Testing

```bash
# AI Service
cd pet-ai-service
pytest tests/ -v

# Backend
cd pet-backend
npm test

# Flutter
cd pet-app
flutter test
flutter test integration_test/
```

## Security

- **Authentication**: JWT with refresh tokens
- **API Security**: API key + IP whitelist for AI service
- **Data Encryption**: AES-256 at rest, TLS 1.3 in transit
- **Rate Limiting**: 60 requests/minute per user
- **AI Safety**: Disclaimers, no definitive diagnoses, human-in-loop for emergencies

## Deployment

### On-Premise (Recommended for AI Service)
```bash
cd pet-infra
powershell -File scripts/setup-onpremise.ps1
```

### Cloud (AWS)
```bash
cd pet-infra
terraform init
terraform apply
```

## License
Proprietary — All Rights Reserved
