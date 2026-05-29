import { test, expect } from '@playwright/test'

test.describe('Repository Health Scan E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/')
    await page.evaluate(() => {
      localStorage.setItem('auth-token', 'test-token')
    })
  })

  test('should scan repository health and display results', async ({ page }) => {
    await page.goto('/repositories')

    // Find a repository card
    const repoCard = page.getByTestId('repo-card').first()
    await expect(repoCard).toBeVisible()

    // Click scan button
    await repoCard.getByRole('button', { name: /scan health/i }).click()

    // Wait for scan to start
    await expect(repoCard.getByText(/scanning/i)).toBeVisible()

    // Wait for scan to complete
    await expect(repoCard.getByTestId('health-score')).toBeVisible({
      timeout: 15000
    })

    // Verify health score is displayed
    const healthScore = await repoCard.getByTestId('health-score').textContent()
    expect(parseInt(healthScore || '0')).toBeGreaterThanOrEqual(0)
    expect(parseInt(healthScore || '0')).toBeLessThanOrEqual(100)

    // Check for health indicator color
    const healthIndicator = repoCard.getByTestId('health-indicator')
    await expect(healthIndicator).toHaveAttribute('data-status', /(healthy|warning|critical)/)
  })

  test('should display health metrics breakdown', async ({ page }) => {
    await page.goto('/repositories/test-repo')

    // Verify metrics are displayed
    const metrics = [
      'commits',
      'pull-requests',
      'issues',
      'contributors',
      'documentation',
      'tests',
      'security'
    ]

    for (const metric of metrics) {
      const metricElement = page.getByTestId(`metric-${metric}`)
      await expect(metricElement).toBeVisible()
      await expect(metricElement).toContainText(/\d+/)
    }

    // Check for recommendations
    await expect(page.getByRole('heading', { name: /recommendations/i })).toBeVisible()
    const recommendations = page.getByTestId('recommendation-item')
    await expect(recommendations.first()).toBeVisible()
  })

  test('should batch scan multiple repositories', async ({ page }) => {
    await page.goto('/repositories')

    // Select multiple repositories
    await page.getByRole('checkbox', { name: /select all/i }).click()

    // Click batch scan button
    await page.getByRole('button', { name: /scan selected/i }).click()

    // Confirm batch operation
    await page.getByRole('button', { name: /confirm/i }).click()

    // Wait for progress indicator
    const progressBar = page.getByTestId('batch-scan-progress')
    await expect(progressBar).toBeVisible()

    // Wait for completion
    await expect(page.getByText(/scan completed/i)).toBeVisible({
      timeout: 30000
    })

    // Verify all repository cards show updated health scores
    const repoCards = page.getByTestId('repo-card')
    const count = await repoCards.count()

    for (let i = 0; i < count; i++) {
      await expect(repoCards.nth(i).getByTestId('last-scanned')).toContainText(/just now|seconds ago/)
    }
  })

  test('should handle rate limiting gracefully', async ({ page }) => {
    // Mock rate limit response
    let requestCount = 0
    await page.route('**/api/scanners/health/trigger', async (route) => {
      requestCount++
      if (requestCount > 3) {
        await route.fulfill({
          status: 429,
          json: { error: 'Rate limit exceeded', retryAfter: 60 }
        })
      } else {
        await route.continue()
      }
    })

    await page.goto('/repositories')

    // Trigger multiple scans quickly
    for (let i = 0; i < 5; i++) {
      const repoCard = page.getByTestId('repo-card').nth(i)
      if (await repoCard.isVisible()) {
        await repoCard.getByRole('button', { name: /scan health/i }).click()
      }
    }

    // Should show rate limit warning
    await expect(page.getByText(/rate limit/i)).toBeVisible()
    await expect(page.getByText(/please wait/i)).toBeVisible()
  })

  test('should show health trends over time', async ({ page }) => {
    await page.goto('/repositories/test-repo')

    // Click on trends tab
    await page.getByRole('tab', { name: /trends/i }).click()

    // Verify chart is displayed
    const chart = page.getByTestId('health-trend-chart')
    await expect(chart).toBeVisible()

    // Check for time range selector
    const timeRangeSelector = page.getByRole('combobox', { name: /time range/i })
    await expect(timeRangeSelector).toBeVisible()

    // Change time range
    await timeRangeSelector.selectOption('30d')

    // Verify chart updates
    await expect(chart).toHaveAttribute('data-range', '30d')

    // Check for data points
    const dataPoints = page.locator('.recharts-dot')
    await expect(dataPoints.first()).toBeVisible()
  })
})