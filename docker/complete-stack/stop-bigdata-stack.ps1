# Stop Big Data Stack
# This script stops all running containers and optionally cleans up volumes

Write-Host "🛑 Stopping Big Data Stack..." -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor Yellow

# Navigate to the docker directory
$dockerDir = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $dockerDir

Write-Host "📍 Working directory: $dockerDir" -ForegroundColor Blue

# Stop and remove containers
Write-Host "🐳 Stopping Docker services..." -ForegroundColor Blue
docker-compose down

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Services stopped successfully!" -ForegroundColor Green
    
    # Ask if user wants to clean up volumes
    $cleanup = Read-Host "`n🗑️  Do you want to remove all data volumes? (y/N)"
    if ($cleanup -eq "y" -or $cleanup -eq "Y") {
        Write-Host "🧹 Cleaning up volumes..." -ForegroundColor Yellow
        docker-compose down -v
        docker volume prune -f
        
        if (Test-Path "volumes") {
            Remove-Item -Recurse -Force "volumes"
            Write-Host "📁 Removed local volumes directory" -ForegroundColor Green
        }
        
        Write-Host "✅ Cleanup completed!" -ForegroundColor Green
    } else {
        Write-Host "💾 Data volumes preserved for next startup" -ForegroundColor Blue
    }
} else {
    Write-Host "`n❌ Error stopping services!" -ForegroundColor Red
}

Write-Host "`n💡 To start again: .\start-bigdata-stack.ps1" -ForegroundColor Cyan