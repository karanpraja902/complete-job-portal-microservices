$ErrorActionPreference = "Stop"

# Set JAVA_HOME to the IntelliJ bundled JDK we found
$env:JAVA_HOME = "E:\IntelliJ IDEA 2026.1.1\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

Write-Output "Using JAVA_HOME: $env:JAVA_HOME"

$services = @(
    @{ name = "Service Registry"; dir = "service-registry"; wait = $true },
    @{ name = "Config Server"; dir = "config-server"; wait = $false },
    @{ name = "API Gateway"; dir = "api-gateway"; wait = $false },
    @{ name = "Job Service"; dir = "job-microservice"; wait = $false },
    @{ name = "Company Service"; dir = "company-microservice"; wait = $false },
    @{ name = "Review Service"; dir = "review-microservice"; wait = $false }
)

foreach ($s in $services) {
    Write-Output "---------------------------------------"
    Write-Output "Starting $($s.name)..."
    
    $workingDir = Join-Path (Get-Location) $s.dir
    
    # Start the service in a new window
    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd '$workingDir'; `$env:JAVA_HOME = '$env:JAVA_HOME'; `$env:PATH = '$env:JAVA_HOME\bin;' + `$env:PATH; ./mvnw spring-boot:run"
    
    if ($s.wait) {
        Write-Output "Waiting for $($s.name) to fully start (this may take a minute)..."
        # Check if Eureka dashboard is up
        $started = $false
        for ($i = 0; $i -lt 30; $i++) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8761" -UseBasicParsing -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $started = $true
                    break
                }
            } catch {}
            Start-Sleep -Seconds 5
        }
        if (-not $started) {
            Write-Warning "Timed out waiting for $($s.name). Proceeding anyway..."
        } else {
            Write-Output "$($s.name) is UP!"
        }
    } else {
        Start-Sleep -Seconds 5
    }
}

Write-Output "---------------------------------------"
Write-Output "All startup commands sent! Check the individual windows for progress."
Write-Output "Registry: http://localhost:8761"
Write-Output "Gateway: http://localhost:8085"
