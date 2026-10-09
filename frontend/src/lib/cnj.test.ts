import { describe, expect, it } from 'vitest'
import { digitsOnly, formatCnj, isValidCnj, maskCnj } from './cnj'

describe('digitsOnly', () => {
  it('keeps only digits', () => {
    expect(digitsOnly('  1001399-31.2023.8.26.0070 ')).toBe('10013993120238260070')
    expect(digitsOnly('abc')).toBe('')
  })
})

describe('maskCnj', () => {
  it.each([
    ['', ''],
    ['1', '1'],
    ['1001399', '1001399'],
    ['10013993', '1001399-3'],
    ['100139931', '1001399-31'],
    ['1001399312', '1001399-31.2'],
    ['10013993120238', '1001399-31.2023.8'],
    ['100139931202382', '1001399-31.2023.8.2'],
    ['10013993120238260', '1001399-31.2023.8.26.0'],
    ['10013993120238260070', '1001399-31.2023.8.26.0070'],
  ])('masks %s progressively', (input, expected) => {
    expect(maskCnj(input)).toBe(expected)
  })

  it('accepts formatted text and ignores letters', () => {
    expect(maskCnj('1001399-31.2023.8.26.0070')).toBe('1001399-31.2023.8.26.0070')
    expect(maskCnj('10a01399')).toBe('1001399')
  })

  it('drops digits beyond 20', () => {
    expect(maskCnj('100139931202382600709999')).toBe('1001399-31.2023.8.26.0070')
  })
})

describe('formatCnj', () => {
  it('formats 20 digits as the canonical number', () => {
    expect(formatCnj('10013993120238260070')).toBe('1001399-31.2023.8.26.0070')
  })
})

describe('isValidCnj', () => {
  it('accepts the demo lawsuit, formatted or digits-only', () => {
    expect(isValidCnj('1001399-31.2023.8.26.0070')).toBe(true)
    expect(isValidCnj('10013993120238260070')).toBe(true)
    expect(isValidCnj('  1001399-31.2023.8.26.0070  ')).toBe(true)
  })

  it('accepts the challenge example', () => {
    expect(isValidCnj('1002271-82.2025.8.26.0003')).toBe(true)
  })

  it('rejects a wrong check digit', () => {
    expect(isValidCnj('1001399-31.2023.8.26.0071')).toBe(false)
  })

  it.each(['', '123', 'abc', '100139931202382600701'])('rejects bad length: %s', (input) => {
    expect(isValidCnj(input)).toBe(false)
  })
})
