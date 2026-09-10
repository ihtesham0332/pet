<div align="center">
  <h1>🐾 AI Pet Health Assistant Platform</h1>
  <p><i>Intelligent veterinary support platform — AI-powered symptom analysis, emergency detection, pet health monitoring, and personalized recommendations.</i></p>

  <!-- Badges -->
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi" alt="FastAPI" />
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
</div>

<hr />

## 📖 Table of Contents
- [Architecture Overview](#-architecture-overview)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [API Endpoints](#-api-endpoints)
- [AI Providers](#-ai-providers)

---

## 🏗️ Architecture Overview

```mermaid
graph TD
    %% Styling
    classDef mobile fill:#02569B,stroke:#fff,stroke-width:2px,color:#fff;
    classDef gateway fill:#E0234E,stroke:#fff,stroke-width:2px,color:#fff;
    classDef ai fill:#009485,stroke:#fff,stroke-width:2px,color:#fff;
    classDef db fill:#336791,stroke:#fff,stroke-width:2px,color:#fff;

    %% Nodes
    A[📱 Flutter Mobile App<br>Riverpod | GoRouter | Dio]:::mobile
    B[🌐 NestJS API Gateway<br>Auth | RBAC | Throttling]:::gateway
    
    C[(PostgreSQL + pgvector)]:::db
    D[(Redis Cache)]:::db
    
    E[🧠 FastAPI AI Service<br>Qwen 7B / 1.5B | BGE-M3]:::ai
    F[☁️ Cloud AI Fallback<br>Longcat / OpenAI]:::ai

    %% Connections
    A -- HTTPS / WSS --> B
    B --> C
    B --> D
    B -- AI Requests --> E
    E -. Fallback .-> F
```

---

## 💻 Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile** | Flutter + Riverpod | Cross-platform iOS/Android Application |
| **Backend** | NestJS + TypeORM | API Gateway, Core Business Logic |
| **AI Service** | FastAPI (Python) | Local LLM inference and AI processing |
| **Local Models** | Qwen2.5 7B/1.5B + BGE-M3 | CPU-optimized GGUF quantized models |
| **Cloud AI** | Longcat (Meituan) / OpenAI | Fallback provider for AI capabilities |
| **Database** | PostgreSQL + pgvector | Application data & RAG embeddings |
| **Cache** | Redis | Session caching & rate limiting |
| **DevOps** | AWS ECS / On-Prem Docker | Container orchestration & Deployment |

---

## 📂 Project Structure

```text
pet-health-assistant/
├── pet-app/                 # 📱 Flutter mobile application
├── pet-backend/             # 🌐 NestJS API Gateway
├── pet-ai-service/          # 🧠 FastAPI AI Service (On-Premise)
├── pet-infra/               # ⚙️ Infrastructure & DevOps (Docker/Terraform)
└── README.md                # 📄 You are here
```

---

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** 3.2+
- **Node.js** 20+
- **Python** 3.12+
- **Docker** & Docker Compose
- **Ollama** (for local AI)

### 1️⃣ Run AI Service (Local)
```bash
# Install Ollama & Pull Models
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5:7b-q4_K_M
ollama pull bge-m3:latest

# Start FastAPI
cd pet-ai-service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### 2️⃣ Run Backend
```bash
cd pet-backend
npm install
npm run start:dev
```

### 3️⃣ Run Mobile App
```bash
cd pet-app
flutter pub get
flutter run
```

*(Alternatively, run everything via Docker Compose: `docker-compose -f pet-infra/docker/docker-compose.yml up -d`)*

---

## 🔌 API Endpoints

### 🟢 NestJS Gateway (Cloud)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/v1/auth/login` | User login (returns JWT) |
| `GET` | `/v1/pets` | List user's pets |
| `POST` | `/v1/symptoms/analyze` | Analyze symptoms |

### 🔵 FastAPI AI Service (Local)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/v1/health` | Service health + model status |
| `POST` | `/v1/symptoms/analyze` | Symptom text analysis |
| `POST` | `/v1/knowledge/query` | RAG knowledge base query |

---

## 🤖 AI Providers

Our AI Router is built for efficiency and reliability:

1. **Local Qwen2.5 (Primary)**: Low latency, zero cost.
2. **Longcat API (Fallback 1)**: Fast cloud inference.
3. **OpenAI GPT-4o-mini (Fallback 2)**: Reliable secondary cloud API.

*Users can easily toggle between Local & Cloud inside the App Settings.*

---
<div align="center">
  <p>Built with ❤️ for happy and healthy pets.</p>
</div>
