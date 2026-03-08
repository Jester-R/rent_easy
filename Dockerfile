# Use official Flutter image
FROM cirrusci/flutter:latest

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Get dependencies
RUN flutter pub get

# Build for web (since we can't use actual device in Docker)
RUN flutter config --enable-web

# Expose port for web server
EXPOSE 8080

# Run the app on web
CMD ["flutter", "run", "-d", "web", "--web-port=8080"]
