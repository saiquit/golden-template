# Use the latest LTS Node version
FROM node:22-alpine

# Set work directory
WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install dependencies
# Note: In development, we use 'npm install'
# RUN npm install

# # Copy the source code
# COPY . .

# # Next.js uses port 3000
# EXPOSE 3000

# # Set environment to development
# ENV NODE_ENV development

# Start Next.js development server
CMD ["npm", "run", "dev"]