import { test, expect, Page, BrowserContext } from '@playwright/test'
import { setupTestDatabase, cleanupTestDatabase } from '../setup/test-database'
import { PrismaClient } from '@prisma/client'

/**
 * END-TO-END TESTS WITH REAL USER WORKFLOWS - NO MOCKS
 * Tests complete user journeys with real data, real APIs, and real browser interactions
 * Simulates actual user behavior patterns and validates entire application flow
 */

let prisma: PrismaClient

test.beforeAll(async () => {
  // Setup real test database before E2E tests
  prisma = await setupTestDatabase()
  console.log('✅ Real test database setup complete for E2E tests')
})

test.afterAll(async () => {
  await cleanupTestDatabase()
  console.log('✅ E2E test cleanup complete')
})

test.describe('Complete User Workflows - Real Data E2E', () => {
  let context: BrowserContext
  let page: Page

  test.beforeEach(async ({ browser }) => {
    // Create new browser context for test isolation
    context = await browser.newContext({
      // Use real viewport dimensions
      viewport: { width: 1920, height: 1080 },
      // Enable real geolocation
      geolocation: { latitude: 40.7128, longitude: -74.0060 },
      permissions: ['geolocation', 'clipboard-read', 'clipboard-write']
    })
    page = await context.newPage()

    // Configure real API base URL
    await page.goto(process.env.DASHBOARD_URL || 'http://localhost:3001')

    // Wait for real application to load
    await page.waitForLoadState('networkidle')
  })

  test.afterEach(async () => {
    await context.close()
  })

  test.describe('User Journey: Repository Health Monitoring', () => {
    test('should complete full repository health monitoring workflow', async () => {
      // Step 1: Navigate to dashboard (real page load)
      await page.goto('/')
      await expect(page.locator('h1')).toContainText('AI-Whisperers Org OS')

      // Step 2: Wait for real repositories to load
      await page.waitForSelector('[data-testid="repo-card"]', { timeout: 10000 })

      const repoCards = page.locator('[data-testid="repo-card"]')
      const repoCount = await repoCards.count()
      expect(repoCount).toBeGreaterThan(0)

      // Step 3: Click on first repository (real user interaction)
      const firstRepo = repoCards.first()
      const repoName = await firstRepo.locator('[data-testid="repo-name"]').textContent()

      await firstRepo.click()

      // Step 4: Navigate to repository details (real navigation)
      await page.waitForURL(/\/repositories\/.*/)
      await expect(page.locator('h1')).toContainText(repoName!)

      // Step 5: Verify real health metrics are displayed
      await expect(page.locator('[data-testid="health-score"]')).toBeVisible()
      await expect(page.locator('[data-testid="last-scanned"]')).toBeVisible()

      const healthScore = await page.locator('[data-testid="health-score"]').textContent()
      const score = parseInt(healthScore!)
      expect(score).toBeGreaterThanOrEqual(0)
      expect(score).toBeLessThanOrEqual(100)

      // Step 6: Trigger health scan (real API call)
      await page.click('[data-testid="scan-health-button"]')

      // Wait for scan to start
      await expect(page.locator('[data-testid="scanning-indicator"]')).toBeVisible()

      // Wait for real scan to complete (may take up to 30 seconds)
      await expect(page.locator('[data-testid="scan-complete"]')).toBeVisible({
        timeout: 30000
      })

      // Step 7: Verify updated health data
      const updatedHealthScore = await page.locator('[data-testid="health-score"]').textContent()
      expect(updatedHealthScore).toBeDefined()

      // Step 8: Check health history chart (real data visualization)
      await page.click('[data-testid="health-history-tab"]')
      await expect(page.locator('[data-testid="health-chart"]')).toBeVisible()

      // Verify chart has real data points
      const dataPoints = page.locator('[data-testid^="chart-point-"]')
      const pointCount = await dataPoints.count()
      expect(pointCount).toBeGreaterThan(0)

      // Step 9: Export health report (real file download)
      const [download] = await Promise.all([
        page.waitForEvent('download'),
        page.click('[data-testid="export-report-button"]')
      ])

      expect(download.suggestedFilename()).toMatch(/health-report.*\.pdf/)

      // Step 10: Verify database was updated with real scan
      const repositories = await prisma.repository.findMany({
        where: { name: repoName! },
        include: {
          healthChecks: {
            orderBy: { scannedAt: 'desc' },
            take: 1
          }
        }
      })

      expect(repositories[0].healthChecks[0]).toBeDefined()
      expect(new Date(repositories[0].healthChecks[0].scannedAt).getTime())
        .toBeGreaterThan(Date.now() - 60000) // Within last minute
    })

    test('should handle multiple repository comparisons', async () => {
      await page.goto('/repositories')

      // Select multiple repositories for comparison
      const repoCheckboxes = page.locator('[data-testid="repo-checkbox"]')
      const repoCount = Math.min(await repoCheckboxes.count(), 3)

      for (let i = 0; i < repoCount; i++) {
        await repoCheckboxes.nth(i).click()
      }

      // Click compare button
      await page.click('[data-testid="compare-repositories"]')

      // Wait for comparison view
      await page.waitForURL(/\/repositories\/compare/)

      // Verify comparison chart with real data
      await expect(page.locator('[data-testid="comparison-chart"]')).toBeVisible()

      // Check that all selected repositories are shown
      const comparedRepos = page.locator('[data-testid="compared-repo"]')
      expect(await comparedRepos.count()).toBe(repoCount)

      // Verify health score comparison
      for (let i = 0; i < repoCount; i++) {
        const healthScore = comparedRepos.nth(i).locator('[data-testid="health-score"]')
        await expect(healthScore).toBeVisible()

        const score = parseInt(await healthScore.textContent()!)
        expect(score).toBeGreaterThanOrEqual(0)
        expect(score).toBeLessThanOrEqual(100)
      }
    })
  })

  test.describe('User Journey: Weekly Report Generation', () => {
    test('should complete full weekly report generation workflow', async () => {
      // Step 1: Navigate to reports section
      await page.goto('/reports')
      await expect(page.locator('h1')).toContainText('Reports')

      // Step 2: Generate new weekly report (real data aggregation)
      await page.click('[data-testid="generate-weekly-report"]')

      // Step 3: Configure report parameters
      const currentDate = new Date()
      const weekNumber = Math.ceil(currentDate.getDate() / 7)

      await page.selectOption('[data-testid="report-week"]', weekNumber.toString())
      await page.selectOption('[data-testid="report-year"]', currentDate.getFullYear().toString())

      // Step 4: Start report generation (real background job)
      await page.click('[data-testid="start-generation"]')

      // Wait for generation to start
      await expect(page.locator('[data-testid="generating-indicator"]')).toBeVisible()

      // Wait for real report generation (may take up to 2 minutes)
      await expect(page.locator('[data-testid="generation-complete"]')).toBeVisible({
        timeout: 120000
      })

      // Step 5: View generated report
      await page.click('[data-testid="view-report"]')
      await page.waitForURL(/\/reports\/org-pulse\/.*/)

      // Step 6: Verify report contains real data
      await expect(page.locator('[data-testid="total-repositories"]')).toBeVisible()
      await expect(page.locator('[data-testid="average-health-score"]')).toBeVisible()
      await expect(page.locator('[data-testid="top-contributors"]')).toBeVisible()

      const totalRepos = await page.locator('[data-testid="total-repositories"]').textContent()
      expect(parseInt(totalRepos!)).toBeGreaterThan(0)

      const avgScore = await page.locator('[data-testid="average-health-score"]').textContent()
      const score = parseFloat(avgScore!)
      expect(score).toBeGreaterThanOrEqual(0)
      expect(score).toBeLessThanOrEqual(100)

      // Step 7: Download report in multiple formats
      const formats = ['markdown', 'html', 'pdf']

      for (const format of formats) {
        const [download] = await Promise.all([
          page.waitForEvent('download'),
          page.click(`[data-testid="download-${format}"]`)
        ])

        expect(download.suggestedFilename()).toMatch(new RegExp(`.*\\.${format}$`))
      }

      // Step 8: Share report via Slack (real webhook)
      await page.click('[data-testid="share-slack"]')

      // Configure Slack sharing
      await page.selectOption('[data-testid="slack-channel"]', '#general')
      await page.fill('[data-testid="slack-message"]', 'Weekly Org Pulse Report - Generated by E2E Test')

      await page.click('[data-testid="send-to-slack"]')

      // Verify successful sharing
      await expect(page.locator('[data-testid="slack-sent-confirmation"]')).toBeVisible({
        timeout: 10000
      })

      // Step 9: Verify report was saved to database
      const reports = await prisma.report.findMany({
        where: {
          week: weekNumber,
          year: currentDate.getFullYear(),
          type: 'ORG_PULSE'
        }
      })

      expect(reports).toHaveLength(1)
      const reportContent = JSON.parse(reports[0].content)
      expect(reportContent).toHaveProperty('totalRepositories')
      expect(reportContent.totalRepositories).toBeGreaterThan(0)
    })
  })

  test.describe('User Journey: Azure DevOps Integration', () => {
    test('should complete work item synchronization workflow', async () => {
      // Step 1: Navigate to synchronization page
      await page.goto('/sync')
      await expect(page.locator('h1')).toContainText('Azure DevOps Sync')

      // Step 2: View current sync status (real data)
      await expect(page.locator('[data-testid="last-sync-time"]')).toBeVisible()
      await expect(page.locator('[data-testid="sync-statistics"]')).toBeVisible()

      // Step 3: Trigger manual sync (real API calls)
      await page.click('[data-testid="trigger-sync"]')

      // Wait for sync to start
      await expect(page.locator('[data-testid="sync-in-progress"]')).toBeVisible()

      // Step 4: Monitor sync progress (real progress updates)
      await expect(page.locator('[data-testid="sync-progress-bar"]')).toBeVisible()

      // Wait for sync completion (may take several minutes)
      await expect(page.locator('[data-testid="sync-complete"]')).toBeVisible({
        timeout: 300000 // 5 minutes
      })

      // Step 5: View sync results
      const syncedItems = await page.locator('[data-testid="synced-items-count"]').textContent()
      expect(parseInt(syncedItems!)).toBeGreaterThanOrEqual(0)

      // Step 6: Navigate to work items view
      await page.click('[data-testid="view-work-items"]')
      await page.waitForURL(/\/work-items/)

      // Step 7: Verify work items are displayed with real data
      const workItemCards = page.locator('[data-testid="work-item-card"]')
      const itemCount = await workItemCards.count()

      if (itemCount > 0) {
        // Click on first work item
        await workItemCards.first().click()

        // Verify work item details
        await expect(page.locator('[data-testid="work-item-title"]')).toBeVisible()
        await expect(page.locator('[data-testid="work-item-state"]')).toBeVisible()
        await expect(page.locator('[data-testid="work-item-type"]')).toBeVisible()

        // Check for GitHub links
        const githubLinks = page.locator('[data-testid="github-link"]')
        if (await githubLinks.count() > 0) {
          // Test link navigation
          const [newPage] = await Promise.all([
            context.waitForEvent('page'),
            githubLinks.first().click()
          ])

          // Verify GitHub page opens
          await newPage.waitForLoadState()
          expect(newPage.url()).toContain('github.com')
          await newPage.close()
        }
      }

      // Step 8: Test work item filtering
      await page.selectOption('[data-testid="state-filter"]', 'Active')

      // Wait for filtered results
      await page.waitForTimeout(1000)

      const filteredItems = page.locator('[data-testid="work-item-card"]')
      const filteredCount = await filteredItems.count()

      // Verify all visible items have "Active" state
      for (let i = 0; i < Math.min(filteredCount, 5); i++) {
        const state = await filteredItems.nth(i).locator('[data-testid="item-state"]').textContent()
        expect(state).toBe('Active')
      }
    })
  })

  test.describe('User Journey: Error Handling and Recovery', () => {
    test('should handle network failures gracefully', async () => {
      // Step 1: Start normal workflow
      await page.goto('/repositories')
      await page.waitForSelector('[data-testid="repo-card"]')

      // Step 2: Simulate network failure
      await context.setOffline(true)

      // Step 3: Try to trigger action that requires network
      await page.click('[data-testid="scan-health-button"]')

      // Step 4: Verify error handling
      await expect(page.locator('[data-testid="network-error"]')).toBeVisible({
        timeout: 10000
      })

      // Step 5: Restore network
      await context.setOffline(false)

      // Step 6: Test retry functionality
      await page.click('[data-testid="retry-button"]')

      // Should now work
      await expect(page.locator('[data-testid="scanning-indicator"]')).toBeVisible()
    })

    test('should recover from API errors', async () => {
      await page.goto('/reports')

      // Try to generate report that might cause API error
      await page.click('[data-testid="generate-weekly-report"]')

      // Use invalid parameters to trigger error
      await page.selectOption('[data-testid="report-week"]', '99') // Invalid week
      await page.click('[data-testid="start-generation"]')

      // Verify error handling
      await expect(page.locator('[data-testid="generation-error"]')).toBeVisible()
      await expect(page.locator('[data-testid="error-message"]')).toContainText('Invalid week number')

      // Test error recovery
      await page.selectOption('[data-testid="report-week"]', '1') // Valid week
      await page.click('[data-testid="start-generation"]')

      // Should now work
      await expect(page.locator('[data-testid="generating-indicator"]')).toBeVisible()
    })
  })

  test.describe('User Journey: Performance and Responsiveness', () => {
    test('should maintain responsiveness under load', async () => {
      // Step 1: Navigate to dashboard with many repositories
      await page.goto('/repositories')

      // Step 2: Measure page load performance
      const startTime = Date.now()
      await page.waitForSelector('[data-testid="repo-card"]')
      const loadTime = Date.now() - startTime

      expect(loadTime).toBeLessThan(3000) // Should load within 3 seconds

      // Step 3: Test rapid interactions
      const repoCards = page.locator('[data-testid="repo-card"]')
      const cardCount = Math.min(await repoCards.count(), 10)

      for (let i = 0; i < cardCount; i++) {
        await repoCards.nth(i).hover()
        await page.waitForTimeout(100)
      }

      // Step 4: Test concurrent operations
      const scanButtons = page.locator('[data-testid="scan-health-button"]')
      const buttonCount = Math.min(await scanButtons.count(), 3)

      // Click multiple scan buttons rapidly
      for (let i = 0; i < buttonCount; i++) {
        await scanButtons.nth(i).click()
      }

      // Should handle concurrent scans gracefully
      await expect(page.locator('[data-testid="scanning-indicator"]')).toHaveCount(buttonCount, {
        timeout: 10000
      })
    })
  })

  test.describe('User Journey: Accessibility and Keyboard Navigation', () => {
    test('should support full keyboard navigation', async () => {
      await page.goto('/')

      // Test Tab navigation
      await page.keyboard.press('Tab')
      await expect(page.locator(':focus')).toBeVisible()

      // Navigate through repository cards using keyboard
      for (let i = 0; i < 5; i++) {
        await page.keyboard.press('Tab')
        const focusedElement = page.locator(':focus')
        await expect(focusedElement).toBeVisible()
      }

      // Test Enter key activation
      const focusedCard = page.locator(':focus')
      if (await focusedCard.getAttribute('data-testid') === 'repo-card') {
        await page.keyboard.press('Enter')
        // Should navigate to repository details
        await page.waitForURL(/\/repositories\/.*/)
      }

      // Test Escape key functionality
      await page.keyboard.press('Escape')
      // Should close any modals or return to previous state
    })

    test('should have proper ARIA labels and screen reader support', async () => {
      await page.goto('/repositories')

      // Check ARIA labels
      const repoCards = page.locator('[data-testid="repo-card"]')
      const firstCard = repoCards.first()

      await expect(firstCard).toHaveAttribute('aria-label')
      await expect(firstCard).toHaveAttribute('role', 'button')
      await expect(firstCard).toHaveAttribute('tabindex', '0')

      // Check health score accessibility
      const healthScore = firstCard.locator('[data-testid="health-score"]')
      await expect(healthScore).toHaveAttribute('aria-label', /Health score: \d+ out of 100/)
    })
  })
})