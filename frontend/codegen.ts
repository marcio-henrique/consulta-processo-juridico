import type { CodegenConfig } from '@graphql-codegen/cli'

const config: CodegenConfig = {
  schema: '../backend/schema.graphql',
  documents: ['src/**/*.graphql'],
  generates: {
    'src/graphql/generated/': {
      preset: 'client',
      presetConfig: {
        gqlTagName: 'gql',
      },
      config: {
        useTypeImports: true,
        // Dates travel as ISO 8601 strings; formatting happens in lib/format.ts.
        scalars: { ISO8601Date: 'string', ISO8601DateTime: 'string' },
      },
    },
  },
  ignoreNoDocuments: true,
}

export default config
