// Post-login redirect targets come from the URL (?next=), so they are
// untrusted: only same-origin relative paths are accepted (open-redirect
// protection, spec 06 requirement 6.3).
const AUTH_PAGES = /^\/(login|cadastro)(?:[/?#]|$)/

export function safeNext(value: string | null | undefined): string {
  if (!value) return '/'
  // Control characters (CR/LF/tab) and backslashes are never legitimate here.
  // eslint-disable-next-line no-control-regex
  if (/[\u0000-\u001f\u007f\\]/.test(value)) return '/'
  if (!value.startsWith('/') || value.startsWith('//')) return '/'
  if (AUTH_PAGES.test(value)) return '/'
  return value
}

export function loginPath(currentPath: string): string {
  const next = safeNext(currentPath)
  return next === '/' ? '/login' : `/login?next=${encodeURIComponent(next)}`
}
