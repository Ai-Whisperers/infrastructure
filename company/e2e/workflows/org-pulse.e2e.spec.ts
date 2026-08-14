import { test, expect } from '@playwright/test'

test.describe('Weekly Org Pulse Generation E2E', () => {
  test.beforeEach(async ({ page }) => {
    // Mock authentication
    await page.goto('/')
    await page.evaluate(() => {
      localStorage.setItem('auth-token', 'test-token')
    })
  })

  test('should generate weekly org pulse report automatically', async ({ page }) => {
    // Navigate to reports section
    await page.goto('/reports')

    // Check for weekly report generation button
    await expect(page.getByRole('button', { name: /generate weekly report/i })).toBeVisible()

    // Trigger manual generation
    await page.getByRole('button', { name: /generate weekly report/i }).click()

    // Wait for generation to start
    await expect(page.getByText(/generating report/i)).toBeVisible()

    // Wait for completion (with timeout)
    await expect(page.getByText(/report generated successfully/i)).toBeVisible({
      timeout: 30000
    })

    // Verify report appears in list
    const reportItem = page.getByTestId('report-item').first()
    await expect(reportItem).toBeVisible()
    await expect(reportItem).toContainText(/Week \d{1,2}, \d{4}/)
  })

  test('should display org pulse metrics correctly', async ({ page }) => {
    await page.goto('/reports/org-pulse/current')

    // Verify key metrics are displayed
    await expect(page.getByTestId('total-repositories')).toBeVisible()
    await expect(page.getByTestId('active-repositories')).toBeVisible()
    await expect(page.getByTestId('average-health-score')).toBeVisible()

    // Check for trend indicators
    const healthTrend = page.getByTestId('health-trend')
    await expect(healthTrend).toBeVisible()
    await expect(healthTrend).toHaveAttribute('data-trend', /(up|down|stable)/)

    // Verify top contributors section
    await expect(page.getByRole('heading', { name: /top contributors/i })).toBeVisible()
    const contributors = page.getByTestId('contributor-card')
    await expect(contributors).toHaveCount(5)
  })

  test('should send Slack notification after report generation', async ({ page, request }) => {
    // Mock Slack webhook
    let slackNotificationSent = false
    await page.route('**/hooks.slack.com/**', async (route) => {
      slackNotificationSent = true
      await route.fulfill({ status: 200 })
    })

    // Generate report
    await page.goto('/reports')
    await page.getByRole('button', { name: /generate weekly report/i }).click()

    // Wait for generation
    await expect(page.getByText(/report generated successfully/i)).toBeVisible({
      timeout: 30000
    })

    // Verify Slack notification was sent
    expect(slackNotificationSent).toBe(true)
  })

  test('should handle report generation failures gracefully', async ({ page }) => {
    // Mock API to fail
    await page.route('**/api/reporters/org-pulse/generate', async (route) => {
      await route.fulfill({
        status: 500,
        json: { error: 'Internal Server Error' }
      })
    })

    await page.goto('/reports')
    await page.getByRole('button', { name: /generate weekly report/i }).click()

    // Should show error message
    await expect(page.getByText(/failed to generate report/i)).toBeVisible()
    await expect(page.getByRole('button', { name: /retry/i })).toBeVisible()
  })

  test('should allow downloading report in multiple formats', async ({ page }) => {
    await page.goto('/reports/org-pulse/current')

    // Check for download options
    await page.getByRole('button', { name: /download/i }).click()

    const downloadMenu = page.getByRole('menu')
    await expect(downloadMenu).toBeVisible()
    await expect(downloadMenu.getByText(/markdown/i)).toBeVisible()
    await expect(downloadMenu.getByText(/html/i)).toBeVisible()
    await expect(downloadMenu.getByText(/pdf/i)).toBeVisible()

    // Test markdown download
    const [download] = await Promise.all([
      page.waitForEvent('download'),
      downloadMenu.getByText(/markdown/i).click()
    ])

    expect(download.suggestedFilename()).toMatch(/org-pulse.*\.md/)
  })
})