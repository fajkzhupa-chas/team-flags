# Week 3: Docker Compose Exploration Lab

> **📚 Navigation:** [Docs Index](README.md) | [Week 2: Single Container](WEEK2_SINGLE_CONTAINER.md) | [Week 3: Docker Compose](WEEK3_BOILER_ROOM.md) | **Exploration Lab**

**Type:** Individual exploration
**Time:** 90-120 minutes (work at your own pace)
**Difficulty:** ⭐ Beginner-friendly

---

## What You'll Do Today

Yesterday you learned about Docker Compose and got everything running. Today is about **understanding HOW it all works** through hands-on exploration.

**No pressure, no breaking things (intentionally), just curiosity-driven learning.**

You'll complete **missions** that help you discover:
- How containers communicate
- Where data actually lives
- How to monitor what's happening
- How to customize your setup

---

## Before You Start

### Prerequisites
- ✅ Completed yesterday's boiler room session
- ✅ Have docker-compose.yml working
- ✅ Services running: `docker compose up -d`

### Check Everything is Running

```bash
# Should show all 3 services as "healthy"
docker compose ps
```

If anything is not running:
```bash
docker compose down
docker compose up -d
```

---

## Mission 1: Become a Container Detective 🔍

**Goal:** Understand what's actually running and using resources

### 1.1 Monitor Resource Usage

Run this command and watch for 30 seconds:
```bash
docker stats
```

**Questions to answer:**
- Which container uses the most memory?
- Which uses the most CPU?
- How much memory does MongoDB use just sitting idle?

**Pro tip:** Press `Ctrl+C` to exit

---

### 1.2 Inspect Container Details

```bash
# See detailed info about the app container
docker compose exec app sh -c "hostname && whoami && pwd"
```

**What you should see:**
- Container's internal hostname
- Username the app runs as (should NOT be root!)
- Current working directory

**Try this:**
```bash
# List all files in the app container
docker compose exec app ls -la

# See what processes are running
docker compose exec app ps aux
```

**Question:** Why do we run as user `nextjs` instead of `root`?

---

### 1.3 Network Discovery

```bash
# List all Docker networks
docker network ls

# Inspect the frontend network
docker network inspect team-flags-edu-frontend-net
```

**Find in the output:**
- How many containers are connected?
- What are their IP addresses?
- What is the subnet range?

**Bonus challenge:**
```bash
# Can nginx reach the app? (should work)
docker compose exec nginx ping -c 3 app

# Can nginx reach the database? (should FAIL)
docker compose exec nginx ping -c 3 db
```

**Question:** Why can nginx reach app but NOT db? (Hint: check docker-compose.yml networks)

---

## Mission 2: Master the Database 💾

**Goal:** Get comfortable interacting with MongoDB

### 2.1 Connect to MongoDB Shell

```bash
# Open MongoDB shell
docker compose exec db mongosh team-flags-edu
```

You're now inside MongoDB! Try these commands:

```javascript
// See what collections (tables) exist
show collections

// Count documents in teams collection
db.teams.countDocuments()

// Exit the shell
exit
```

---

### 2.2 Add Some Test Data

```bash
# Create a test team (run this from your terminal, not inside mongosh)
docker compose exec db mongosh team-flags-edu --eval '
  db.teams.insertOne({
    name: "Team Awesome",
    members: ["Alice", "Bob", "Charlie"],
    score: 100,
    createdAt: new Date()
  })
'
```

**Verify it worked:**
```bash
docker compose exec db mongosh team-flags-edu --eval 'db.teams.find().pretty()'
```

**Now add YOUR team:**
```bash
docker compose exec db mongosh team-flags-edu --eval '
  db.teams.insertOne({
    name: "YOUR-TEAM-NAME-HERE",
    members: ["Your", "Team", "Members"],
    score: 9000,
    createdAt: new Date()
  })
'
```

---

### 2.3 Test Data Persistence

This is important - does data survive restarts?

```bash
# 1. Check current data
docker compose exec db mongosh team-flags-edu --eval 'db.teams.countDocuments()'
# Remember this number!

# 2. Stop all containers
docker compose down

# 3. Start them again
docker compose up -d

# 4. Wait for containers to be healthy
docker compose ps

# 5. Check if data still exists
docker compose exec db mongosh team-flags-edu --eval 'db.teams.countDocuments()'
```

**Question:** Is the count the same? Why does data persist even though containers were stopped?

**Hint:** Look for `volumes:` in docker-compose.yml

---

## Mission 3: Log Investigation 📋

**Goal:** Learn to read logs and understand what containers are doing

### 3.1 View All Logs

```bash
# See logs from all services
docker compose logs --tail=20
```

**Too much?** Filter by service:

```bash
# Just nginx logs
docker compose logs nginx --tail=20

# Just app logs
docker compose logs app --tail=20

# Just database logs
docker compose logs db --tail=20
```

---

### 3.2 Follow Logs in Real-Time

Open a **second terminal window** and run:
```bash
docker compose logs -f app
```

Now in your **first terminal**, make a request:
```bash
curl http://localhost/api/health
```

**Watch the second terminal** - you should see the request logged!

Press `Ctrl+C` in the second terminal when done.

---

### 3.3 Find Evidence in Logs

Generate some activity:
```bash
# Make multiple requests
curl http://localhost/
curl http://localhost/api/health
curl http://localhost/api/health
curl http://localhost/
```

Now search logs:
```bash
# Find all health check requests
docker compose logs nginx | grep health

# See app startup messages
docker compose logs app | grep Ready
```

**Challenge:** Find the timestamp when the app container became ready after last restart.

---

## Mission 4: Customize Your Setup ⚙️

**Goal:** Make changes and see them take effect

### 4.1 Change the Nginx Port

```bash
# Stop containers
docker compose down

# Edit your .env file
nano .env
# or
code .env
# or
vim .env
```

Change this line:
```bash
NGINX_PORT=80
```
To:
```bash
NGINX_PORT=8080
```

Save and restart:
```bash
docker compose up -d
```

**Test it:**
```bash
# Old port should fail
curl http://localhost:80
# Should get "Connection refused"

# New port should work
curl http://localhost:8080/api/health
```

**Don't forget to change it back to 80 when done!**

---

### 4.2 Add a Custom Environment Variable

Edit your `.env` file and add:
```bash
MY_CUSTOM_MESSAGE="Hello from [YOUR NAME]"
```

Edit `docker-compose.yml` and add to the `app` service environment:
```yaml
  app:
    build: .
    environment:
      - MONGODB_URI=${MONGODB_URI}
      - NODE_ENV=${NODE_ENV:-production}
      - MY_CUSTOM_MESSAGE=${MY_CUSTOM_MESSAGE}  # Add this line
```

Restart and verify:
```bash
docker compose down
docker compose up -d

# Check if the variable is inside the container
docker compose exec app printenv MY_CUSTOM_MESSAGE
```

**You should see your message!**

---

### 4.3 Explore Nginx Configuration

```bash
# Read the nginx config
cat nginx/nginx.conf
```

**Find these important parts:**
- `upstream nextjs` - How nginx knows where the app is
- `location /` - Main application route
- `proxy_set_header` - Headers added to requests
- Security headers (X-Frame-Options, etc.)

**Experiment:** Add a new security header

Edit `nginx/nginx.conf` and find the headers section. Add:
```nginx
add_header X-Custom-Header "Protected by [YOUR NAME]" always;
```

Rebuild and test:
```bash
docker compose up -d --build nginx

# Check if your header appears
curl -I http://localhost/ | grep X-Custom-Header
```

---

## Mission 5: Container Communication Test 🔗

**Goal:** Understand how services talk to each other

### 5.1 Test the Request Flow

```bash
# 1. From your computer to nginx
curl http://localhost/health
# Should return: nginx OK

# 2. From nginx to app (running command INSIDE nginx container)
docker compose exec nginx wget -qO- http://app:3000/api/health
# Should return JSON with health status

# 3. From app to database (running command INSIDE app container)
docker compose exec app sh -c 'echo "db.adminCommand(\"ping\")" | mongosh $MONGODB_URI --quiet'
# Should return: { ok: 1 }
```

**What you proved:**
- ✅ Your computer → nginx → works
- ✅ nginx → app → works
- ✅ app → database → works

This is the **complete request chain!**

---

### 5.2 Understand Service Names

Inside Docker networks, containers use **service names** as hostnames.

```bash
# App container can ping 'db' (the service name)
docker compose exec app ping -c 2 db

# Nginx can ping 'app' (the service name)
docker compose exec nginx ping -c 2 app
```

But from your computer, those names don't work:
```bash
# This will FAIL
ping db
ping app
```

**Why?** Service names only work INSIDE Docker networks, not on your host machine.

---

## Mission 6: Health Check Deep Dive 🏥

**Goal:** Understand how Docker knows if containers are healthy

### 6.1 See Health Status

```bash
docker compose ps
```

Look at the STATUS column - should show `(healthy)` for all services.

**What if we break something?**

```bash
# Temporarily stop MongoDB
docker compose stop db

# Wait 30 seconds, then check status
sleep 30
docker compose ps
```

**You should see:**
- db: Exited
- app: Up (unhealthy) - because it can't reach the database!
- nginx: Still healthy (it only checks if nginx itself works)

**Fix it:**
```bash
docker compose start db

# Wait and check again
sleep 30
docker compose ps
# App should become healthy again!
```

---

### 6.2 Manually Run Health Checks

Each service has a health check. Let's run them manually:

```bash
# Nginx health check
docker compose exec nginx wget --quiet --tries=1 --spider http://localhost/health && echo "✅ Nginx healthy"

# App health check
docker compose exec app wget --quiet --tries=1 --spider http://localhost:3000/api/health && echo "✅ App healthy"

# MongoDB health check
docker compose exec db mongosh --eval "db.adminCommand('ping')" && echo "✅ MongoDB healthy"
```

---

## Mission 7: Volume Exploration 📦

**Goal:** Understand where data is actually stored

### 7.1 List Volumes

```bash
# See all Docker volumes
docker volume ls

# Find the one for MongoDB (should be team-flags-edu_mongo-data)
docker volume inspect team-flags-edu_mongo-data
```

**Look for `"Mountpoint"`** - this is where MongoDB data lives on your computer!

---

### 7.2 See Volume Usage

```bash
# How much space is the MongoDB volume using?
docker system df -v | grep mongo-data
```

---

### 7.3 Backup Challenge (Advanced)

Want to backup your database?

```bash
# Create a backup
docker compose exec db mongodump --db team-flags-edu --out /tmp/backup

# Copy backup from container to your computer
docker compose cp db:/tmp/backup ./mongo-backup

# You now have a backup folder!
ls -la mongo-backup
```

**To restore later:**
```bash
docker compose cp ./mongo-backup db:/tmp/restore
docker compose exec db mongorestore --db team-flags-edu /tmp/restore/team-flags-edu
```

---

## Final Challenge: Put It All Together 🎯

Complete this multi-step challenge that uses everything you learned:

### The Challenge

1. **Add data to your database** (3 different teams with your names)
2. **Verify data exists** using mongosh
3. **Stop all containers**
4. **Start containers on a different port** (change NGINX_PORT)
5. **Verify data still exists** after restart
6. **Check resource usage** of all containers
7. **View logs** to find when the app became ready
8. **Make a request** through nginx and see it in the logs

### Verification

When complete, run this and save the output:

```bash
echo "=== Container Status ==="
docker compose ps

echo -e "\n=== Data Count ==="
docker compose exec db mongosh team-flags-edu --quiet --eval 'db.teams.countDocuments()'

echo -e "\n=== Resource Usage ==="
docker stats --no-stream

echo -e "\n=== Health Checks ==="
curl -s http://localhost:$(grep NGINX_PORT .env | cut -d'=' -f2)/api/health | head -1
```

**Take a screenshot of this output!**

---

## Reflection Questions

Answer these in your own words (no wrong answers):

1. **What surprised you most today?**

2. **Which command will you use most often?**

3. **Explain in your own words: How does nginx know where to send requests?**

4. **What happens if you run `docker compose down -v`?** (Don't actually run it!)

5. **Why do we use volumes instead of storing data inside containers?**

---

## Achievements Unlocked 🏆

Check off what you completed:

- [ ] Viewed resource usage with docker stats
- [ ] Connected to MongoDB shell
- [ ] Added your own data to the database
- [ ] Verified data persists across restarts
- [ ] Viewed logs from all services
- [ ] Changed the nginx port and verified it works
- [ ] Added a custom environment variable
- [ ] Tested container-to-container communication
- [ ] Understood why network isolation matters
- [ ] Ran health checks manually
- [ ] Found where MongoDB data is stored
- [ ] Completed the final challenge
- [ ] Can explain the architecture to someone else

**Completed 8+?** You're doing great! ✅
**Completed 12+?** You've mastered the basics! 🌟

---

## What's Next?

### If you finish early:

**Easy experiments:**
- Add more teams to the database
- Try different MongoDB queries
- Explore the app container filesystem
- Read nginx logs and find specific requests

**Medium challenges:**
- Change MongoDB database name (requires editing .env and docker-compose.yml)
- Add another environment variable and use it
- Figure out how to see environment variables inside nginx container

**Advanced (optional):**
- Create a script that automates health checking all services
- Make a backup and restore script
- Document your own troubleshooting runbook

---

## Clean Up (End of Day)

When you're done experimenting:

```bash
# Stop containers but keep data
docker compose down

# OR if you want to start fresh next time (WARNING: deletes data!)
docker compose down -v
```

---

## Resources

- [Docker Compose Cheat Sheet](https://devhints.io/docker-compose)
- [MongoDB Shell Quick Reference](https://www.mongodb.com/docs/mongodb-shell/reference/)
- [Docker Stats Documentation](https://docs.docker.com/engine/reference/commandline/stats/)
- [Week 3 Boiler Room Guide](WEEK3_BOILER_ROOM.md)

---

## Need Help?

**Stuck on something?**
- Read the error message carefully (it usually tells you what's wrong)
- Check `docker compose ps` to see if containers are healthy
- Look at logs with `docker compose logs [service-name]`
- Ask a neighbor or instructor
- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)

---

**Have fun exploring! The best way to learn is to be curious and experiment.**

Remember: You can't really break anything permanent - worst case, you run `docker compose down -v` and start fresh!

---

> **📚 Navigation:** [Docs Index](README.md) | [Week 2: Single Container](WEEK2_SINGLE_CONTAINER.md) | [Week 3: Docker Compose](WEEK3_BOILER_ROOM.md) | **Exploration Lab**
