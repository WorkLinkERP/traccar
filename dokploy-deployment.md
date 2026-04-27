# Dokploy Deployment Guide for Traccar

## Prerequisites
- Dokploy instance running on your VPS
- Domain name pointed to your VPS IP
- SSL certificates (optional but recommended)

## Deployment Steps

### 1. Prepare Environment Variables
Copy the example environment file and update it:
```bash
cp .env.example .env
```

Update the `.env` file with your production values:
- Set strong passwords for database and admin
- Configure your domain name
- Set up email credentials if needed

### 2. Create MySQL Configuration (Optional)
Create `mysql/conf.d/my.cnf` for production optimization:
```ini
[mysqld]
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
max_connections = 200
query_cache_size = 64M
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
```

### 3. Set Up SSL Certificates (Optional)
If using HTTPS with nginx:
```bash
mkdir -p nginx/ssl
# Copy your SSL certificates to nginx/ssl/
# cert.pem and key.pem
```

### 4. Dokploy Configuration

#### Option A: Using Docker Compose
1. In Dokploy, create a new application
2. Choose "Docker Compose" deployment
3. Upload `docker-compose.prod.yml`
4. Add environment variables from `.env` file
5. Set deployment path to your repository

#### Option B: Using Git Repository
1. Push your code to a Git repository
2. In Dokploy, create a new application
3. Connect your Git repository
4. Set build command: `docker-compose -f docker-compose.prod.yml build`
5. Set start command: `docker-compose -f docker-compose.prod.yml up -d`
6. Add environment variables

### 5. Network Configuration
- Ensure ports 80, 443, 5010-5060 are open on your VPS firewall
- Configure DNS records to point to your VPS IP

### 6. Health Checks
Dokploy will automatically use the health checks defined in the compose file:
- Database: MySQL connection test
- Traccar: HTTP health check on port 8082
- Nginx: Container status

### 7. Monitoring
- Check logs: `docker-compose logs -f traccar`
- Monitor resource usage in Dokploy dashboard
- Set up alerts for container restarts

## Post-Deployment Setup

### 1. Access Traccar
- Without nginx: `http://your-vps-ip:8082`
- With nginx: `https://your-domain.com`

### 2. Initial Configuration
1. Login with default credentials (admin/admin)
2. Change admin password immediately
3. Configure server settings
4. Set up email notifications (if configured)
5. Create user accounts as needed

### 3. GPS Device Configuration
- Configure your GPS devices to connect to ports 5010-5060
- Use your VPS IP or domain as the server address
- Select appropriate protocol for your devices

## Security Recommendations

1. **Network Security**
   - Use HTTPS with SSL certificates
   - Implement firewall rules
   - Consider VPN access for administration

2. **Application Security**
   - Change all default passwords
   - Use strong database credentials
   - Enable rate limiting (configured in nginx)

3. **Data Security**
   - Regular database backups
   - Monitor access logs
   - Keep Traccar updated

## Troubleshooting

### Common Issues
- **Port conflicts**: Ensure ports 80, 443, 5010-5060 are available
- **Database connection**: Check MySQL credentials and network
- **SSL errors**: Verify certificate paths and permissions
- **Memory issues**: Adjust resource limits in compose file

### Debug Commands
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f traccar
docker-compose logs -f database

# Access database
docker-compose exec database mysql -u traccar -p

# Restart services
docker-compose restart traccar
```

## Maintenance

### Regular Tasks
- Update Traccar image: `docker-compose pull traccar`
- Backup database regularly
- Monitor disk space and logs
- Review security updates

### Scaling
- For high load, consider database clustering
- Use load balancer for multiple Traccar instances
- Implement Redis for session storage (advanced)
