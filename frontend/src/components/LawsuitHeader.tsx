import { Link } from 'react-router-dom'

type Props = {
  // CNJ number shown as "Processo <number>". Ignored when `heading` is set.
  number?: string
  // Full heading text for states without a lawsuit (not found, error).
  heading?: string
}

// The page always renders this single h1, so the element that receives focus
// on route change survives the loading -> loaded transition (WCAG 2.4.3).
export function LawsuitHeader({ number, heading }: Props) {
  return (
    <div className="lawsuit-header">
      <h1 className="lawsuit-header__number">
        {heading ?? `Processo ${number}`}
      </h1>
      <Link to="/">Nova consulta</Link>
    </div>
  )
}
