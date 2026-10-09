// Client-side mirror of backend/app/lib/cnj_number.rb (CNJ Resolution 65/2008),
// for fast feedback only. The server stays authoritative.
// Format: NNNNNNN-DD.AAAA.J.TR.OOOO (20 digits).

const DIGITS_LENGTH = 20

export function digitsOnly(input: string): string {
  return input.replace(/\D/g, '')
}

// Progressive mask while typing: digits beyond 20 are dropped.
export function maskCnj(input: string): string {
  const d = digitsOnly(input).slice(0, DIGITS_LENGTH)
  let out = d.slice(0, 7)
  if (d.length > 7) out += '-' + d.slice(7, 9)
  if (d.length > 9) out += '.' + d.slice(9, 13)
  if (d.length > 13) out += '.' + d.slice(13, 14)
  if (d.length > 14) out += '.' + d.slice(14, 16)
  if (d.length > 16) out += '.' + d.slice(16, 20)
  return out
}

export function formatCnj(digits: string): string {
  return maskCnj(digits)
}

// 98 - ((sequence + year + branch + court + origin + "00") mod 97), zero padded.
// The modulo is computed in chunks so the 20-digit number never loses precision.
function checkDigits(d: string): string {
  const base = d.slice(0, 7) + d.slice(9, 20) + '00'
  let remainder = 0
  for (const char of base) {
    remainder = (remainder * 10 + Number(char)) % 97
  }
  return String(98 - remainder).padStart(2, '0')
}

export function isValidCnj(input: string): boolean {
  const d = digitsOnly(input)
  if (d.length !== DIGITS_LENGTH) return false
  return d.slice(7, 9) === checkDigits(d)
}
