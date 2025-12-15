# MuSheet Server

A Serverpod-based backend for the MuSheet music sheet management application.

## Architecture

The server is built with [Serverpod](https://serverpod.dev/), a next-generation app and web server framework for Flutter. It provides:

- **User Authentication**: Username/password authentication with secure session management
- **Team Collaboration**: Multi-team support with shared scores and annotations
- **Cloud Sync**: Offline-first synchronization with CRDT-based conflict resolution
- **File Storage**: PDF and image storage for music sheets
- **Admin Dashboard**: User and system management

## Prerequisites

- Dart SDK 3.0+
- Docker and Docker Compose
- PostgreSQL 15+ (via Docker)
- Redis 7+ (via Docker)

## Project Structure

```
server/
├── musheet_server/          # Main Serverpod project
│   ├── bin/                 # Entry points
│   ├── lib/
│   │   ├── src/
│   │   │   ├── endpoints/   # API endpoints
│   │   │   ├── protocol/    # Model definitions (YAML)
│   │   │   ├── exceptions/  # Custom exceptions
│   │   │   └── generated/   # Auto-generated code
│   │   └── server.dart      # Server configuration
│   ├── config/              # Environment configs
│   └── Dockerfile
├── nginx/                   # Nginx configuration
├── scripts/                 # Deployment scripts
├── docker-compose.yml       # Docker orchestration
└── .env.example             # Environment template
```

## Quick Start

### 1. Clone and Setup

```bash
cd server
cp .env.example .env
# Edit .env with your configuration
```

### 2. Development Mode

```bash
cd musheet_server

# Install dependencies
dart pub get

# Generate Serverpod protocol
dart pub run serverpod generate

# Start development database
docker-compose up -d postgres redis

# Run the server
dart run bin/main.dart
```

### 3. Production Deployment

```bash
cd server

# Full deployment
./scripts/deploy.sh production full

# Or step by step:
./scripts/deploy.sh production build
./scripts/deploy.sh production deploy
```

## API Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `POST /auth/changePassword` - Change password

### Admin User Management
- `POST /adminUser/registerAdmin` - Register first admin
- `POST /adminUser/createUser` - Create new user
- `GET /adminUser/listUsers` - List all users
- `PUT /adminUser/updateUser` - Update user
- `DELETE /adminUser/deleteUser` - Delete user
- `POST /adminUser/resetPassword` - Reset user password

### Profile
- `GET /profile/getProfile` - Get user profile
- `PUT /profile/updateProfile` - Update profile
- `POST /profile/uploadAvatar` - Upload avatar
- `GET /profile/searchUsers` - Search users

### Scores
- `GET /score/getScores` - Get user's scores
- `GET /score/getScoreById` - Get score by ID
- `POST /score/createScore` - Create score
- `PUT /score/updateScore` - Update score
- `DELETE /score/deleteScore` - Delete score
- `POST /score/syncScores` - Sync scores

### Files
- `POST /file/uploadPdf` - Upload PDF
- `GET /file/downloadPdf` - Download PDF
- `DELETE /file/deletePdf` - Delete PDF

### Setlists
- `GET /setlist/getSetlists` - Get setlists
- `POST /setlist/createSetlist` - Create setlist
- `PUT /setlist/updateSetlist` - Update setlist
- `DELETE /setlist/deleteSetlist` - Delete setlist

### Teams
- `POST /team/createTeam` - Create team
- `GET /team/getMyTeams` - Get user's teams
- `POST /team/joinTeam` - Join team by invite code
- `DELETE /team/leaveTeam` - Leave team
- `PUT /team/updateTeam` - Update team

### Team Resources
- `GET /teamScore/getTeamScores` - Get team scores
- `POST /teamScore/shareScore` - Share score with team
- `GET /teamSetlist/getTeamSetlists` - Get team setlists
- `POST /teamSetlist/shareSetlist` - Share setlist with team
- `GET /teamAnnotation/getTeamAnnotations` - Get team annotations
- `POST /teamAnnotation/addTeamAnnotation` - Add team annotation

### Admin Dashboard
- `GET /admin/getDashboardStats` - Get dashboard stats
- `GET /admin/getAllUsers` - Get all users (paginated)
- `GET /admin/getAllTeams` - Get all teams
- `PUT /admin/deactivateUser` - Deactivate user
- `PUT /admin/promoteToAdmin` - Promote to admin

### Sync
- `POST /sync/syncAll` - Full sync
- `POST /sync/pushChanges` - Push local changes
- `GET /sync/getSyncStatus` - Get sync status

### Status
- `GET /status/health` - Health check
- `GET /status/info` - Server info
- `GET /status/ping` - Ping

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | Database username | `musheet` |
| `POSTGRES_PASSWORD` | Database password | - |
| `POSTGRES_DB` | Database name | `musheet` |
| `REDIS_PASSWORD` | Redis password | - |
| `JWT_SECRET` | JWT signing secret | - |
| `LOG_LEVEL` | Logging level | `info` |

## Docker Services

| Service | Port | Description |
|---------|------|-------------|
| `musheet_server` | 8080 | API Server |
| `musheet_server` | 8081 | Insights (Admin) |
| `musheet_server` | 8082 | Web Server |
| `postgres` | 5432 | PostgreSQL |
| `redis` | 6379 | Redis |
| `nginx` | 80/443 | Reverse Proxy |

## Database Migrations

Serverpod handles migrations automatically. To manually manage migrations:

```bash
cd musheet_server
dart pub run serverpod create-migration
dart pub run serverpod apply-migrations
```

## Backup

To enable automated backups:

```bash
docker-compose --profile with-backup up -d backup
```

Backups are stored in the `backup_data` volume and retained for 7 days.

## SSL/TLS

For production with SSL:

1. Place your certificates in `nginx/ssl/`:
   - `fullchain.pem`
   - `privkey.pem`

2. Start with nginx profile:
```bash
docker-compose --profile with-nginx up -d
```

## Monitoring

The Insights dashboard is available at port 8081 and provides:
- Request logging
- Performance metrics
- Error tracking

Access it at `http://localhost:8081/insights`

## License

Proprietary - All rights reserved