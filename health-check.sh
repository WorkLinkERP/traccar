#!/bin/bash

# Health check script for Traccar deployment
# Can be used with Dokploy or as standalone monitoring

set -e

# Configuration
TRACCAR_URL="${TRACCAR_URL:-http://localhost:8082}"
DATABASE_HOST="${DATABASE_HOST:-localhost}"
DATABASE_USER="${DATABASE_USER:-traccar}"
DATABASE_PASSWORD="${DATABASE_PASSWORD:-traccar123}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    
    case $status in
        "OK")
            echo -e "${GREEN}[OK]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "INFO")
            echo -e "[INFO] $message"
            ;;
    esac
}

# Check Traccar web interface
check_traccar_web() {
    print_status "INFO" "Checking Traccar web interface..."
    
    if curl -s -f "$TRACCAR_URL/api/health" > /dev/null 2>&1; then
        print_status "OK" "Traccar web interface is responding"
        return 0
    else
        print_status "ERROR" "Traccar web interface is not responding"
        return 1
    fi
}

# Check database connection
check_database() {
    print_status "INFO" "Checking database connection..."
    
    if mysqladmin ping -h "$DATABASE_HOST" -u "$DATABASE_USER" -p"$DATABASE_PASSWORD" 2>/dev/null; then
        print_status "OK" "Database connection is working"
        return 0
    else
        print_status "ERROR" "Database connection failed"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    print_status "INFO" "Checking disk space..."
    
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -lt 80 ]; then
        print_status "OK" "Disk space usage: ${usage}%"
        return 0
    elif [ "$usage" -lt 90 ]; then
        print_status "WARN" "Disk space usage: ${usage}% (getting high)"
        return 1
    else
        print_status "ERROR" "Disk space usage: ${usage}% (critical)"
        return 2
    fi
}

# Check memory usage
check_memory() {
    print_status "INFO" "Checking memory usage..."
    
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [ "$mem_usage" -lt 80 ]; then
        print_status "OK" "Memory usage: ${mem_usage}%"
        return 0
    elif [ "$mem_usage" -lt 90 ]; then
        print_status "WARN" "Memory usage: ${mem_usage}% (getting high)"
        return 1
    else
        print_status "ERROR" "Memory usage: ${mem_usage}% (critical)"
        return 2
    fi
}

# Check container status (if Docker is available)
check_containers() {
    if command -v docker >/dev/null 2>&1; then
        print_status "INFO" "Checking Docker containers..."
        
        local containers=("traccar-server-prod" "traccar-mysql-prod")
        local failed_containers=()
        
        for container in "${containers[@]}"; do
            if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
                print_status "OK" "Container $container is running"
            else
                print_status "ERROR" "Container $container is not running"
                failed_containers+=("$container")
            fi
        done
        
        if [ ${#failed_containers[@]} -eq 0 ]; then
            return 0
        else
            return 1
        fi
    else
        print_status "WARN" "Docker not available, skipping container checks"
        return 0
    fi
}

# Check GPS ports
check_gps_ports() {
    print_status "INFO" "Checking GPS tracking ports..."
    
    local ports=(5010 5011 5012 5013 5014 5015)
    local failed_ports=()
    
    for port in "${ports[@]}"; do
        if netstat -ln | grep -q ":$port "; then
            print_status "OK" "Port $port is listening"
        else
            print_status "WARN" "Port $port is not listening"
            failed_ports+=("$port")
        fi
    done
    
    if [ ${#failed_ports[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Main health check
main() {
    print_status "INFO" "Starting Traccar health check..."
    echo "================================"
    
    local exit_code=0
    
    # Run all checks
    check_traccar_web || exit_code=$?
    check_database || exit_code=$?
    check_disk_space || exit_code=$?
    check_memory || exit_code=$?
    check_containers || exit_code=$?
    check_gps_ports || exit_code=$?
    
    echo "================================"
    
    if [ $exit_code -eq 0 ]; then
        print_status "OK" "All health checks passed"
    else
        print_status "ERROR" "Some health checks failed"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"
