import { AxeBuilder } from '@axe-core/playwright'
import { expect, test } from '@playwright/test'

// Smoke test: the app boots and the home page has no serious accessibility
// violations. Real user flows are added by spec 05.
test('home page loads and has no serious a11y violations', async ({ page }) => {
  await page.goto('/')

  await expect(page.getByRole('heading', { level: 1 })).toBeVisible()

  const results = await new AxeBuilder({ page }).analyze()
  const serious = results.violations.filter(
    (violation) => violation.impact === 'serious' || violation.impact === 'critical',
  )
  expect(serious).toEqual([])
})
