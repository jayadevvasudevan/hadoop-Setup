# Start Big Data Stack
# This script starts the complete Hadoop ecosystem with monitoring

Write-Host "🚀 Starting Big Data Stack..." -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Yellow

# Check if Docker is running
$dockerStatus = docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not running! Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Navigate to the docker directory
$dockerDir = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $dockerDir

Write-Host "📍 Working directory: $dockerDir" -ForegroundColor Blue

# Create volumes directory if it doesn't exist
if (!(Test-Path "volumes")) {
    New-Item -ItemType Directory -Path "volumes" -Force
    Write-Host "📁 Created volumes directory" -ForegroundColor Green
}

# Start the services
Write-Host "🐳 Starting Docker services..." -ForegroundColor Blue
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Services started successfully!" -ForegroundColor Green
    Write-Host "`n🌐 Web UIs will be available at:" -ForegroundColor Yellow
    Write-Host "   Hadoop NameNode:     http://localhost:9870" -ForegroundColor Cyan
    Write-Host "   YARN ResourceManager: http://localhost:8088" -ForegroundColor Cyan
    Write-Host "   Spark Master:        http://localhost:8080" -ForegroundColor Cyan
    Write-Host "   Spark Worker:        http://localhost:8081" -ForegroundColor Cyan
    Write-Host "   Jupyter Notebook:    http://localhost:8888" -ForegroundColor Cyan
    Write-Host "   HiveServer2:         http://localhost:10002" -ForegroundColor Cyan
    
    Write-Host "`n⏳ Please wait 2-3 minutes for all services to fully initialize..." -ForegroundColor Yellow
    Write-Host "`n📊 To monitor containers: docker-compose logs -f [service-name]" -ForegroundColor Blue
    Write-Host "🛑 To stop services: docker-compose down" -ForegroundColor Blue
} else {
    Write-Host "`n❌ Failed to start services! Check the error messages above." -ForegroundColor Red
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   - Ensure ports 9870, 8088, 8080, 8081, 8888, 10000, 3306 are free" -ForegroundColor White
    Write-Host "   - Check Docker logs: docker-compose logs [service-name]" -ForegroundColor White
    Write-Host "   - Try: docker-compose down && docker-compose up -d" -ForegroundColor White
}