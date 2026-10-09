import { AxeBuilder } from '@axe-core/playwright'
import { expect, test } from '@playwright/test'
import type { Page } from '@playwright/test'

// End-to-end flow against the real stack (docker compose up): anonymous
// redirect, sign up, search, summary, movements paging, not found, sign out.
// Requires the lawsuits to be imported (the api container does it on start).
const KNOWN = '1001399-31.2023.8.26.0070'
const NOT_IN_DATA = '1002271-82.2025.8.26.0003'
const TAGS = ['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']

async function expectNoSeriousViolations(page: Page) {
  const results = await new AxeBuilder({ page }).withTags(TAGS).analyze()
  const serious = results.violations.filter((v) => v.impact === 'serious' || v.impact === 'critical')
  expect(serious.map((v) => `${v.id}: ${v.help}`)).toEqual([])
}

test('anonymous visit, sign up, lookup, paging, not found and sign out', async ({ page }) => {
  const email = `e2e-${Date.now()}@example.com`

  // Anonymous visitors are sent to the login page and keep their destination.
  await page.goto(`/processos/${KNOWN}`)
  await expect(page).toHaveURL(/\/login\?next=/)
  await expect(page.getByRole('heading', { level: 1, name: 'Entrar' })).toBeVisible()
  await expectNoSeriousViolations(page)

  await page.getByRole('link', { name: 'Criar conta' }).click()
  await expect(page.getByRole('heading', { level: 1, name: 'Criar conta' })).toBeVisible()
  await page.getByLabel(/^E-mail/).fill(email)
  await page.getByLabel(/^Senha/).fill('short')
  await page.getByRole('button', { name: 'Criar conta' }).click()
  await expect(page.getByText('A senha deve ter de 10 a 72 caracteres.')).toBeVisible()
  await expectNoSeriousViolations(page)

  await page.getByLabel(/^Senha/).fill('a-very-safe-password')
  await page.getByRole('button', { name: 'Criar conta' }).click()

  // Back at the page the visitor wanted.
  await expect(page.getByRole('heading', { level: 1, name: `Processo ${KNOWN}` })).toBeVisible()
  await expect(page.getByText(email)).toBeVisible()
  await expect(page.locator('dd', { hasText: 'R$ 10.000,00' })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Resumo do processo' })).toBeVisible()
  await expect(page.getByTestId('summary-paragraph').first()).toBeVisible({ timeout: 60_000 })
  await expect(page.getByText(/Resumo gerado por inteligência artificial/)).toBeVisible()
  await expect(page.getByRole('row')).toHaveCount(26)
  await expectNoSeriousViolations(page)

  await page.getByRole('button', { name: 'Carregar mais' }).click()
  await expect(page.getByRole('row')).toHaveCount(47)
  await expect(page.getByRole('button', { name: 'Carregar mais' })).toHaveCount(0)

  // Search from the home page: invalid, then not found.
  await page.getByRole('link', { name: 'Nova consulta' }).click()
  await page.getByLabel('Número do processo').fill('123')
  await page.getByRole('button', { name: 'Consultar' }).click()
  await expect(page.getByRole('alert')).toHaveText('Número de processo inválido. Confira os dígitos.')
  await page.getByLabel('Número do processo').fill(NOT_IN_DATA.replace(/\D/g, ''))
  await expect(page.getByLabel('Número do processo')).toHaveValue(NOT_IN_DATA)
  await page.getByRole('button', { name: 'Consultar' }).click()
  await expect(page.getByRole('heading', { level: 1, name: 'Processo não encontrado na base.' })).toBeVisible()
  await expectNoSeriousViolations(page)

  // The session cookie is HttpOnly and SameSite=Lax; nothing in web storage.
  const cookie = (await page.context().cookies()).find((c) => c.name === '_lawsuit_session')
  expect(cookie?.httpOnly).toBe(true)
  expect(cookie?.sameSite).toBe('Lax')
  expect(await page.evaluate(() => localStorage.length + sessionStorage.length)).toBe(0)

  await page.getByRole('button', { name: 'Sair' }).click()
  await expect(page).toHaveURL(/\/login$/)
  await page.goto('/')
  await expect(page).toHaveURL(/\/login$/)
})

test('layout reflows at 320 px without page-level horizontal scroll', async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 640 })
  await page.goto('/login')
  await page.getByLabel(/^E-mail/).waitFor()
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
  expect(overflow).toBeLessThanOrEqual(0)
})
