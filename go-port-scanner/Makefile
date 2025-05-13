# Variables
APP_NAME := port-scan-exe
SRC := ./...

# Default target
all: build

# Build the application
build:
	go build -o $(APP_NAME) .

# Run the application
run: build
	./$(APP_NAME)

# Run tests
test:
	go test -v $(SRC)

# Clean up build artifacts
clean:
	rm -f $(APP_NAME)

# Format the code
fmt:
	go fmt $(SRC)

# Lint the code (requires golangci-lint installed)
lint:
	golangci-lint run

# Run everything (build, test, and run)
full: clean fmt lint test build run

.PHONY: all build run test clean fmt lint full
