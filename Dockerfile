# --- Builder Stage ---
FROM node:18-alpine AS builder

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy source code
COPY . .

# Build step if needed
# RUN npm run build

# --- Final Stage ---
FROM node:18-alpine

# Create a non-root user in the final image
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy only necessary artifacts from builder
COPY --from=builder /app /app

# Install only production dependencies
RUN npm prune --production

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Start command
CMD ["node", "server.js"]
