
# Team Flags EDU - Production-Grade Dockerfile
# Multi-stage build for optimal image size and security
# This Dockerfile demonstrates DevSecOps best practices
#
# Week 3: Docker Compose - This image works with docker-compose.yml
# Week 5+: Add Firebase credentials for authentication features
#
# Build: docker build -t team-flags-edu .
# Run:   docker run -p 3000:3000 -e MONGODB_URI=... team-flags-edu

# ============================================
 upstream/main
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# --- VIKTIGT: Miljövariabler för att klara bygget ---
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
<<<<<<< HEAD
ENV SKIP_ENV_VALIDATION=true
ENV MONGODB_URI=mongodb://localhost:27017/dummy
=======

# Build-time environment variables (dummy values for build only)
# Real values are passed at runtime via docker-compose.yml or -e flags
# MongoDB and Firebase are optional - app works without them for Week 2-4
ENV MONGODB_URI=""
>>>>>>> upstream/main
ENV MONGODB_DB=team-flags-edu
ENV STUDENTS_COLLECTION=students
# Denna rad fixar "project_id"-felet
ENV FIREBASE_SERVICE_ACCOUNT='{"project_id": "nordtech-dummy"}'

# --- MASTER FIX FÖR BUILD-FEL ---
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV SKIP_ENV_VALIDATION=true

# MongoDB dummy-värden
ENV MONGODB_URI=mongodb://localhost:27017/dummy
ENV MONGODB_DB=team-flags-edu
ENV STUDENTS_COLLECTION=students

# Firebase dummy-värden - vi lägger till flera namn för säkerhets skull
ENV FIREBASE_SERVICE_ACCOUNT='{"project_id": "nordtech-dummy"}'
ENV FIREBASE_ADMIN_SERVICE_ACCOUNT='{"project_id": "nordtech-dummy"}'
ENV GOOGLE_PROJECT_ID="nordtech-dummy"
ENV NEXT_PUBLIC_FIREBASE_PROJECT_ID="nordtech-dummy"
# --------------------------------

RUN npm run build

# Stage 3: Runner (Den slutgiltiga, säkra imagen)
FROM node:20-alpine AS runner
WORKDIR /app

<<<<<<< HEAD
=======
# Install wget for health checks
RUN apk add --no-cache wget

# Security: Create a non-root user
# Running as root is a security risk
>>>>>>> upstream/main
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Kopiera endast det som behövs för att köra appen
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/next.config.ts ./next.config.ts 2>/dev/null || COPY --from=builder /app/next.config.js ./next.config.js 2>/dev/null
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV HOSTNAME="0.0.0.0"
ENV PORT=3000

<<<<<<< HEAD
=======
# Health check - Docker Compose uses this to verify the app is ready
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/health || exit 1

# Start the Next.js application
# Standalone mode uses server.js directly
>>>>>>> upstream/main
CMD ["node", "server.js"]
