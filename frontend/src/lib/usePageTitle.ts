import { useEffect } from 'react'

export const APP_NAME = 'Consulta de Processo'

// Every route sets a unique, descriptive document.title (WCAG 2.4.2).
export function usePageTitle(title: string) {
  useEffect(() => {
    document.title = `${title} | ${APP_NAME}`
  }, [title])
}
