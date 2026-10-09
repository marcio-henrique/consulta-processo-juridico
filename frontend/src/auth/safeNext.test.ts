import { describe, expect, it } from 'vitest'
import { loginPath, safeNext } from './safeNext'

describe('safeNext', () => {
  it('accepts same-origin relative paths, with query and hash', () => {
    expect(safeNext('/')).toBe('/')
    expect(safeNext('/processos/1001399-31.2023.8.26.0070')).toBe('/processos/1001399-31.2023.8.26.0070')
    expect(safeNext('/processos/1?x=1#top')).toBe('/processos/1?x=1#top')
  })

  it.each([
    '//evil.com',
    '//evil.com/path',
    '/\\evil.com',
    'https://evil.com',
    'http://evil.com/x',
    'javascript:alert(1)',
    'evil.com',
    '',
    '/ok\nLocation: evil',
    '/ok\r\n',
    '/\tevil',
  ])('falls back to / for %j', (value) => {
    expect(safeNext(value)).toBe('/')
  })

  it('falls back to / for missing values', () => {
    expect(safeNext(null)).toBe('/')
    expect(safeNext(undefined)).toBe('/')
  })

  it('does not send the user back to the auth pages', () => {
    expect(safeNext('/login')).toBe('/')
    expect(safeNext('/cadastro?next=/x')).toBe('/')
  })
})

describe('loginPath', () => {
  it('encodes the current path in next', () => {
    expect(loginPath('/processos/1?x=1')).toBe('/login?next=%2Fprocessos%2F1%3Fx%3D1')
  })

  it('omits next for the home page', () => {
    expect(loginPath('/')).toBe('/login')
  })
})
