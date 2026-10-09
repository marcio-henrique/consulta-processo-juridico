// First focusable element of the page (WCAG 2.4.1).
export function SkipLink({ targetId }: { targetId: string }) {
  return (
    <a className="skip-link" href={`#${targetId}`}>
      Ir para o conteúdo
    </a>
  )
}
