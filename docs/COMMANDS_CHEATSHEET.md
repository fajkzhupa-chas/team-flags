# Docker Compose Commands Cheat Sheet

Quick reference for Week 3 Exploration Lab

---

## Essential Commands

### Starting & Stopping

```bash
# Start all services (foreground, shows logs)
docker compose up

# Start all services (background)
docker compose up -d

# Stop all services (keeps data)
docker compose down

# Stop and DELETE all data (volumes)
docker compose down -v

# Restart a specific service
docker compose restart app

# Rebuild and start
docker compose up --build
```

---

## Monitoring

### Check Status
```bash
# See which containers are running
docker compose ps

# Real-time resource usage
docker stats

# Disk usage
docker system df
```

### View Logs
```bash
# All logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Specific service
docker compose logs app

# Last 20 lines only
docker compose logs --tail=20 app

# With timestamps
docker compose logs -f --timestamps
```

---

## Working Inside Containers

### Execute Commands
```bash
# Run a command in a container
docker compose exec [service] [command]

# Examples:
docker compose exec app sh          # Open shell in app
docker compose exec db mongosh       # Open MongoDB shell
docker compose exec nginx sh         # Open shell in nginx
```

### Common Inspection Commands
```bash
# See environment variables
docker compose exec app printenv

# See running processes
docker compose exec app ps aux

# See files
docker compose exec app ls -la

# Check current user
docker compose exec app whoami
```

---

## Database (MongoDB)

### Connect to Database
```bash
# Open MongoDB shell
docker compose exec db mongosh team-flags-edu
```

### Inside MongoDB Shell
```javascript
// Show all collections
show collections

// Count documents
db.teams.countDocuments()

// Find all teams
db.teams.find()

// Pretty print
db.teams.find().pretty()

// Insert a document
db.teams.insertOne({name: "Test", members: []})

// Exit shell
exit
```

### Run MongoDB Commands from Terminal
```bash
# One-line MongoDB command
docker compose exec db mongosh team-flags-edu --eval 'db.teams.find()'

# Ping database
docker compose exec db mongosh --eval "db.adminCommand('ping')"
```

---

## Networks

```bash
# List all networks
docker network ls

# Inspect a network
docker network inspect team-flags-edu-frontend-net

# Test connectivity
docker compose exec nginx ping -c 3 app
docker compose exec app ping -c 3 db
```

---

## Volumes

```bash
# List volumes
docker volume ls

# Inspect a volume
docker volume inspect team-flags-edu_mongo-data

# Copy files from container
docker compose cp db:/tmp/backup ./local-backup

# Copy files to container
docker compose cp ./local-file db:/tmp/file
```

---

## Health Checks

```bash
# Manual health checks
curl http://localhost/health                    # Nginx
curl http://localhost/api/health                # App via nginx
docker compose exec app wget -qO- http://localhost:3000/api/health  # App direct
docker compose exec db mongosh --eval "db.adminCommand('ping')"     # MongoDB
```

---

## Debugging

### When Something's Wrong

```bash
# 1. Check status
docker compose ps

# 2. Check logs for errors
docker compose logs app
docker compose logs --tail=50 app

# 3. Inspect configuration
docker compose config

# 4. Restart from scratch
docker compose down
docker compose up --build

# 5. Nuclear option (deletes everything!)
docker compose down -v
docker compose up --build
```

### Common Issues

**Port already in use:**
```bash
# Change port in .env file
NGINX_PORT=8080
```

**Container unhealthy:**
```bash
# Check health check
docker compose exec app wget -qO- http://localhost:3000/api/health
```

**Changes not applying:**
```bash
# Force rebuild
docker compose up --build --force-recreate
```

---

## File Editing

```bash
# Using nano (beginner-friendly)
nano .env
# Ctrl+O to save, Ctrl+X to exit

# Using vim
vim .env
# Press 'i' to edit, 'Esc' then ':wq' to save

# Using VS Code
code .env
```

---

## Useful Combinations

```bash
# See logs and status together
docker compose ps && docker compose logs --tail=10

# Quick restart of app only
docker compose restart app && docker compose logs -f app

# Full rebuild and follow logs
docker compose up --build && docker compose logs -f

# Stop, remove everything, rebuild
docker compose down -v && docker compose up --build -d
```

---

## Grep for Log Search

```bash
# Find specific text in logs
docker compose logs | grep "error"
docker compose logs app | grep "Ready"
docker compose logs nginx | grep "health"

# Case insensitive
docker compose logs | grep -i "error"
```

---

## Environment Variables

```bash
# View all environment variables in a container
docker compose exec app printenv

# View specific variable
docker compose exec app printenv MONGODB_URI

# Test with custom variable
docker compose exec app sh -c 'echo $MY_CUSTOM_MESSAGE'
```

---

## Quick Tests

```bash
# Test nginx
curl http://localhost/health

# Test app health
curl http://localhost/api/health

# Test with headers
curl -I http://localhost/

# Pretty print JSON
curl -s http://localhost/api/health | python -m json.tool
```

---

## Advanced (Optional)

```bash
# Build without cache
docker compose build --no-cache

# Scale a service (if supported)
docker compose up -d --scale app=3

# See resource limits
docker inspect team-flags-edu-app | grep -A 10 Resources

# Export logs to file
docker compose logs > logs.txt

# Watch logs matching pattern
docker compose logs -f | grep --line-buffered "error"
```

---

## Emergency Commands

```bash
# Kill everything Docker-related (USE WITH CAUTION!)
docker compose down -v
docker system prune -a --volumes

# Just restart Docker Desktop instead! 😅
```

---

## Print This Section!

### Top 10 Commands You'll Use Today

1. `docker compose ps` - Check status
2. `docker compose logs app` - View logs
3. `docker compose exec app sh` - Enter container
4. `docker compose exec db mongosh team-flags-edu` - Database shell
5. `docker compose down` - Stop services
6. `docker compose up -d` - Start services
7. `docker stats` - Resource usage
8. `curl http://localhost/api/health` - Test health
9. `docker network inspect team-flags-edu-frontend-net` - Check network
10. `docker volume ls` - List volumes

---

**Pro Tip:** Keep this cheat sheet open in a second terminal window while you work!
