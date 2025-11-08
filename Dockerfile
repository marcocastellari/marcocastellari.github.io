# Use the official Hugo extended image
FROM hugomods/hugo:exts

# Set working directory
WORKDIR /src

# Fix Git ownership issue (for mounted volumes)
RUN git config --global --add safe.directory /src

# Expose port
EXPOSE 1313

# Default command
CMD ["hugo", "server", "--bind", "0.0.0.0", "--buildDrafts", "--buildFuture"]
