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
ENV SKIP_ENV_VALIDATION=true
ENV MONGODB_URI=mongodb://localhost:27017/dummy
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

CMD ["node", "server.js"]
