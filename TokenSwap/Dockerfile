# Use official Ruby image as base
FROM ruby:3.2-slim

# Set working directory
WORKDIR /app

# Copy Gemfile first for better caching
COPY Gemfile ./

# Install bundler and gems
RUN gem install bundler && bundle install

# Copy the server file
COPY server.rb .

# Expose the port the app runs on
EXPOSE 1234

# Run the server with bundler
CMD ["bundle", "exec", "ruby", "server.rb"]

