# AI-Whisperers Org OS - Test Runner Script
# Automates test execution and coverage reporting

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "unit", "integration", "e2e", "coverage", "watch")]
    [string]$TestType = "all",

    [Parameter(Mandatory=$false)]
    [ValidateSet("dashboard", "jobs", "both")]
    [string]$Service = "both",

    [Parameter(Mandatory=$false)]
    [switch]$CI = $false,

    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false,

    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport = $false
)

$ErrorActionPreference = "Stop"
$script:startTime = Get-Date

# Colors for output
$colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Default = "White"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "Default"
    )
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Test-Prerequisites {
    Write-ColorOutput "`n🔍 Checking prerequisites..." "Info"

    # Check Node.js
    $nodeVersion = node --version 2>$null
    if (-not $nodeVersion) {
        Write-ColorOutput "❌ Node.js is not installed" "Error"
        exit 1
    }
    Write-ColorOutput "✅ Node.js: $nodeVersion" "Success"

    # Check npm
    $npmVersion = npm --version 2>$null
    if (-not $npmVersion) {
        Write-ColorOutput "❌ npm is not installed" "Error"
        exit 1
    }
    Write-ColorOutput "✅ npm: $npmVersion" "Success"

    # Check if dependencies are installed
    if (-not (Test-Path "node_modules")) {
        Write-ColorOutput "📦 Installing dependencies..." "Warning"
        npm ci
    }
}

function Run-UnitTests {
    param([string]$TargetService)

    Write-ColorOutput "`n🧪 Running unit tests for $TargetService..." "Info"

    $testCommand = "npm test -- --coverage --silent"
    if ($CI) {
        $testCommand += " --ci --maxWorkers=2"
    }

    $paths = @{
        "dashboard" = "apps/dashboard"
        "jobs" = "services/jobs"
    }

    if ($TargetService -eq "both") {
        foreach ($service in $paths.Keys) {
            Push-Location $paths[$service]
            try {
                Write-ColorOutput "  Testing $service..." "Default"
                Invoke-Expression $testCommand
                if ($LASTEXITCODE -ne 0) {
                    throw "Unit tests failed for $service"
                }
            }
            finally {
                Pop-Location
            }
        }
    }
    else {
        Push-Location $paths[$TargetService]
        try {
            Invoke-Expression $testCommand
            if ($LASTEXITCODE -ne 0) {
                throw "Unit tests failed for $TargetService"
            }
        }
        finally {
            Pop-Location
        }
    }

    Write-ColorOutput "✅ Unit tests completed successfully" "Success"
}

function Run-IntegrationTests {
    Write-ColorOutput "`n🔗 Running integration tests..." "Info"

    # Start test database
    if ($CI -eq $false) {
        Write-ColorOutput "  Starting test database..." "Default"
        docker-compose -f docker-compose.test.yml up -d postgres redis 2>$null
        Start-Sleep -Seconds 5
    }

    try {
        $env:NODE_ENV = "test"
        $env:DATABASE_URL = "postgresql://testuser:testpass@localhost:5432/testdb"
        $env:REDIS_URL = "redis://localhost:6379"

        npm run test:integration
        if ($LASTEXITCODE -ne 0) {
            throw "Integration tests failed"
        }

        Write-ColorOutput "✅ Integration tests completed successfully" "Success"
    }
    finally {
        if ($CI -eq $false) {
            Write-ColorOutput "  Stopping test database..." "Default"
            docker-compose -f docker-compose.test.yml down 2>$null
        }
    }
}

function Run-E2ETests {
    Write-ColorOutput "`n🌐 Running E2E tests..." "Info"

    # Install Playwright browsers if needed
    if (-not (Test-Path "$env:USERPROFILE\.cache\ms-playwright")) {
        Write-ColorOutput "  Installing Playwright browsers..." "Warning"
        npx playwright install --with-deps
    }

    # Build applications
    Write-ColorOutput "  Building applications..." "Default"
    npm run build

    # Run E2E tests
    $env:CI = if ($CI) { "true" } else { "false" }
    npx playwright test

    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ E2E tests failed" "Error"
        Write-ColorOutput "  View report: npx playwright show-report" "Warning"
        throw "E2E tests failed"
    }

    Write-ColorOutput "✅ E2E tests completed successfully" "Success"
}

function Run-CoverageAnalysis {
    Write-ColorOutput "`n📊 Running coverage analysis..." "Info"

    # Run tests with coverage
    npm run test:coverage

    # Generate coverage report
    $coverageFile = "coverage/lcov.info"
    if (Test-Path $coverageFile) {
        $coverage = Get-Content $coverageFile | Select-String "^SF:" | Measure-Object
        $lines = Get-Content $coverageFile | Select-String "^DA:" | Where-Object { $_ -match ",1$" } | Measure-Object
        $totalLines = Get-Content $coverageFile | Select-String "^DA:" | Measure-Object

        if ($totalLines.Count -gt 0) {
            $percentage = [math]::Round(($lines.Count / $totalLines.Count) * 100, 2)
            Write-ColorOutput "  Coverage: $percentage%" $(if ($percentage -ge 80) { "Success" } else { "Warning" })
        }

        # Check coverage thresholds
        if ($percentage -lt 80) {
            Write-ColorOutput "⚠️  Coverage is below 80% threshold" "Warning"
        }
    }

    if ($GenerateReport) {
        Write-ColorOutput "  Generating HTML coverage report..." "Default"
        npx nyc report --reporter=html
        Write-ColorOutput "  Report available at: coverage/index.html" "Info"
    }
}

function Run-WatchMode {
    Write-ColorOutput "`n👁️  Starting test watch mode..." "Info"
    Write-ColorOutput "  Press Ctrl+C to exit" "Warning"

    if ($Service -eq "both") {
        Write-ColorOutput "  Note: Watch mode runs for dashboard by default" "Warning"
        $Service = "dashboard"
    }

    $path = if ($Service -eq "dashboard") { "apps/dashboard" } else { "services/jobs" }
    Push-Location $path
    try {
        npm run test:watch
    }
    finally {
        Pop-Location
    }
}

function Generate-TestReport {
    Write-ColorOutput "`n📝 Generating test report..." "Info"

    $reportPath = "test-results"
    if (-not (Test-Path $reportPath)) {
        New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
    }

    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        duration = ((Get-Date) - $script:startTime).TotalSeconds
        testType = $TestType
        service = $Service
        results = @{}
    }

    # Collect test results
    if (Test-Path "coverage/coverage-summary.json") {
        $coverage = Get-Content "coverage/coverage-summary.json" | ConvertFrom-Json
        $report.results.coverage = @{
            lines = $coverage.total.lines.pct
            statements = $coverage.total.statements.pct
            functions = $coverage.total.functions.pct
            branches = $coverage.total.branches.pct
        }
    }

    # Collect Jest results
    if (Test-Path "test-results/jest-results.json") {
        $jestResults = Get-Content "test-results/jest-results.json" | ConvertFrom-Json
        $report.results.tests = @{
            total = $jestResults.numTotalTests
            passed = $jestResults.numPassedTests
            failed = $jestResults.numFailedTests
            pending = $jestResults.numPendingTests
        }
    }

    # Save report
    $reportFile = "$reportPath/test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 10 | Out-File $reportFile

    Write-ColorOutput "✅ Test report saved to: $reportFile" "Success"

    # Display summary
    Write-ColorOutput "`n📊 Test Summary:" "Info"
    Write-ColorOutput "  Duration: $([math]::Round($report.duration, 2))s" "Default"

    if ($report.results.tests) {
        $passRate = [math]::Round(($report.results.tests.passed / $report.results.tests.total) * 100, 2)
        Write-ColorOutput "  Tests: $($report.results.tests.passed)/$($report.results.tests.total) passed ($passRate%)" $(if ($passRate -eq 100) { "Success" } else { "Warning" })
    }

    if ($report.results.coverage) {
        Write-ColorOutput "  Coverage: $($report.results.coverage.lines)%" $(if ($report.results.coverage.lines -ge 80) { "Success" } else { "Warning" })
    }
}

# Main execution
try {
    Write-ColorOutput "🚀 AI-Whisperers Org OS - Test Runner" "Info"
    Write-ColorOutput "==========================================" "Info"

    Test-Prerequisites

    switch ($TestType) {
        "all" {
            Run-UnitTests -TargetService $Service
            Run-IntegrationTests
            Run-E2ETests
            Run-CoverageAnalysis
        }
        "unit" {
            Run-UnitTests -TargetService $Service
        }
        "integration" {
            Run-IntegrationTests
        }
        "e2e" {
            Run-E2ETests
        }
        "coverage" {
            Run-CoverageAnalysis
        }
        "watch" {
            Run-WatchMode
        }
    }

    if ($GenerateReport) {
        Generate-TestReport
    }

    $duration = [math]::Round(((Get-Date) - $script:startTime).TotalSeconds, 2)
    Write-ColorOutput "`n✨ All tests completed successfully in ${duration}s!" "Success"
    exit 0
}
catch {
    Write-ColorOutput "`n❌ Test execution failed: $_" "Error"
    if ($Verbose) {
        Write-ColorOutput $_.Exception.StackTrace "Error"
    }
    exit 1
}