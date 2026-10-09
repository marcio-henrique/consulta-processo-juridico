import { describe, expect, it } from 'vitest'
import { formatDate, splitParagraphs } from './format'

describe('formatDate', () => {
  it('converts ISO dates without timezone shifts', () => {
    expect(formatDate('2023-12-05')).toBe('05/12/2023')
    expect(formatDate('2024-01-01')).toBe('01/01/2024')
  })

  it('uses only the date part of a datetime', () => {
    expect(formatDate('2024-06-12T23:59:59-03:00')).toBe('12/06/2024')
  })

  it('returns the input when it is not an ISO date', () => {
    expect(formatDate('not a date')).toBe('not a date')
  })
})

describe('splitParagraphs', () => {
  it('splits on blank lines and trims', () => {
    expect(splitParagraphs('Um.\n\nDois.\r\n\r\n  Três.  ')).toEqual(['Um.', 'Dois.', 'Três.'])
  })

  it('ignores empty paragraphs', () => {
    expect(splitParagraphs('\n\n')).toEqual([])
  })
})
