FROM node:18-alpine

WORKDIR /app

# Copy dependency definitions
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install

# Copy all project files
COPY . .

# Ensure entrypoint is executable
RUN chmod +x ./docker/entrypoint.sh

# Start the container using the entrypoint script
CMD ["/bin/sh", "./docker/entrypoint.sh"]