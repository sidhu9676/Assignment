# --- Build Stage ---
FROM node:18-alpine AS builder

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Optional build step
# RUN npm run build

# --- Final Stage ---
FROM node:18-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy from builder
COPY --from=builder /app /app

# Remove dev dependencies
RUN npm prune --production

# Change ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["node", "server.js"]
