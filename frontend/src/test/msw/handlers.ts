import { HttpResponse, graphql } from 'msw'
import { digitsOnly, formatCnj, isValidCnj } from '../../lib/cnj'

// Default handlers for tests, built from docs/contracts (section 4). Tests
// override individual operations with server.use(...).

export const DEMO_NUMBER = '1001399-31.2023.8.26.0070' // has a cached summary
export const NO_SUMMARY_NUMBER = '1019112-71.2025.8.26.0224' // summary is generated on demand
export const NOT_IN_DATA_NUMBER = '1002271-82.2025.8.26.0003' // valid CNJ, not imported

export const DEMO_USER = { __typename: 'User', id: '1', email: 'ana@example.com' }

export const SUMMARY_BODY =
  'O processo 1001399-31.2023.8.26.0070 tramita na 2ª Vara Cível do Foro de Batatais e discute um valor de R$ 10.000,00.\n\n' +
  'Ao longo do processo, houve várias etapas: apresentação do pedido, defesa, decisões do juiz e publicações oficiais.\n\n' +
  'A última movimentação registrada foi em 12/06/2024.'

export const LONG_CONTENT = 'Texto longo do cartório. '.repeat(20).trim() // > 300 characters

export function buildMovements(total: number) {
  return Array.from({ length: total }, (_, index) => ({
    __typename: 'Movement',
    id: String(1000 + index),
    // Newest first, like the API.
    date: new Date(Date.UTC(2024, 5, 12 - index)).toISOString().slice(0, 10),
    title: index === 0 ? 'Certidão de Publicação Expedida' : `Movimentação ${index + 1}`,
    content: index === 1 ? LONG_CONTENT : index === 2 ? null : `Conteúdo ${index + 1}\nSegunda linha`,
  }))
}

type LawsuitFixture = {
  number: string
  movementsTotal: number
  summary: boolean
}

const LAWSUITS: LawsuitFixture[] = [
  { number: DEMO_NUMBER, movementsTotal: 46, summary: true },
  { number: NO_SUMMARY_NUMBER, movementsTotal: 6, summary: false },
]

export function lawsuitPayload(
  number: string,
  { first = 25, after = null }: { first?: number; after?: string | null },
) {
  const fixture = LAWSUITS.find((item) => item.number === number)
  if (!fixture) return null
  const all = buildMovements(fixture.movementsTotal)
  const offset = after ? Number(after) : 0
  const nodes = all.slice(offset, offset + first)
  const end = offset + nodes.length
  return {
    __typename: 'Lawsuit',
    number: fixture.number,
    forum: 'Foro de Batatais',
    court: '2ª Vara Cível',
    numberOfAuthors: 1,
    movementsCount: fixture.movementsTotal,
    value: { __typename: 'Money', amount: '10000.00', formatted: 'R$ 10.000,00' },
    latestSummary: fixture.summary
      ? {
          __typename: 'Summary',
          id: '10',
          body: SUMMARY_BODY,
          generatedAt: '2026-10-08T12:00:00Z',
        }
      : null,
    movements: {
      __typename: 'MovementConnection',
      nodes,
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: end < all.length,
        endCursor: String(end),
      },
    },
  }
}

export const userError = (code: string, message: string, field: string | null = null) => ({
  __typename: 'UserError',
  code,
  message,
  field,
})

export const handlers = [
  graphql.query('Lawsuit', ({ variables }) => {
    const raw = String(variables.number ?? '')
    if (!isValidCnj(raw)) {
      return HttpResponse.json({
        data: {
          lawsuit: {
            __typename: 'LawsuitPayload',
            lawsuit: null,
            errors: [
              userError('INVALID_CNJ', 'Número de processo inválido. Confira os dígitos.', 'number'),
            ],
          },
        },
      })
    }
    const lawsuit = lawsuitPayload(formatCnj(digitsOnly(raw)), {
      first: variables.first ?? 25,
      after: variables.after ?? null,
    })
    return HttpResponse.json({
      data: {
        lawsuit: {
          __typename: 'LawsuitPayload',
          lawsuit,
          errors: lawsuit ? [] : [userError('NOT_FOUND', 'Processo não encontrado na base.')],
        },
      },
    })
  }),

  graphql.mutation('GenerateSummary', () =>
    HttpResponse.json({
      data: {
        generateSummary: {
          __typename: 'GenerateSummaryPayload',
          summary: {
            __typename: 'Summary',
            id: '11',
            body: SUMMARY_BODY,
            generatedAt: '2026-10-09T12:00:00Z',
          },
          errors: [],
        },
      },
    }),
  ),

  graphql.query('Me', () => HttpResponse.json({ data: { me: DEMO_USER } })),

  graphql.mutation('SignIn', ({ variables }) => {
    const { email, password } = variables.input
    const ok = email === DEMO_USER.email && password === 'a-very-safe-password'
    return HttpResponse.json({
      data: {
        signIn: {
          __typename: 'AuthPayload',
          user: ok ? DEMO_USER : null,
          errors: ok ? [] : [userError('UNAUTHENTICATED', 'E-mail ou senha inválidos.')],
        },
      },
    })
  }),

  graphql.mutation('SignUp', ({ variables }) => {
    const { email, password } = variables.input
    const errors = []
    if (email === 'taken@example.com') errors.push(userError('VALIDATION_FAILED', 'Este e-mail já está em uso.', 'email'))
    else if (!email.includes('@')) errors.push(userError('VALIDATION_FAILED', 'Informe um e-mail válido.', 'email'))
    if (password.length < 10) {
      errors.push(userError('VALIDATION_FAILED', 'A senha deve ter de 10 a 72 caracteres.', 'password'))
    }
    return HttpResponse.json({
      data: {
        signUp: {
          __typename: 'AuthPayload',
          user: errors.length ? null : { ...DEMO_USER, email },
          errors,
        },
      },
    })
  }),

  graphql.mutation('SignOut', () =>
    HttpResponse.json({
      data: { signOut: { __typename: 'SignOutPayload', success: true, errors: [] } },
    }),
  ),
]
