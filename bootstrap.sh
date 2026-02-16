#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Fullstack Bootstrap..."

# 1. Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "📄 Creating .env file..."
    cat <<EOF > .env
POSTGRES_DB=app_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
DJANGO_DEBUG=True
DJANGO_SECRET_KEY=generate-a-random-string-here
DJANGO_DEBUG=True
NEXT_PUBLIC_API_URL=http://localhost/api
EOF
fi

# 2. Generate Django (if not already there)
if [ ! -f "backend/manage.py" ]; then
    echo "🐍 Bootstrapping Django..."
    docker run --rm -v "$(pwd)/backend:/app" -w /app python:3.12-slim \
        sh -c "pip install django && django-admin startproject core ."
fi

# 3. Generate Next.js (Fixed Logic)
if [ ! -f "frontend/package.json" ]; then
    echo "⚛️ Bootstrapping Next.js..."
    # 1. Run the generator into a subfolder called 'tmp_next'
    docker run --rm -v "$(pwd)/frontend:/app" -w /app node:22-alpine \
        npx create-next-app@latest tmp_next --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm --no-install --yes
    
    # 2. Move files from 'tmp_next' to 'frontend' root
    # Note: We use 'shopt' or a simple 'mv' to handle hidden files like .eslintrc
    sudo mv frontend/tmp_next/* frontend/ 2>/dev/null || true
    sudo mv frontend/tmp_next/.* frontend/ 2>/dev/null || true
    
    # 3. Clean up the temp directory
    sudo rm -rf frontend/tmp_next
    echo "✅ Next.js files moved to root."
fi

# 4. Fix Permissions (For Fedora/Linux)
echo "🔒 Fixing ownership to $USER..."
sudo chown -R $USER:$USER .

# 5. Build and Start
echo "🏗️ Building and starting containers..."
docker compose up --build -d

# 6. Database Migration
echo "🗄️ Waiting for DB and running migrations..."
sleep 5
docker compose exec backend python manage.py migrate

echo "✅ SETUP COMPLETE!"
echo "Next.js: http://localhost"
echo "Django Admin: http://localhost/admin"