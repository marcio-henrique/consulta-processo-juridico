module Errors
  # Single source of truth for user-facing (pt-BR) error messages returned
  # as UserError { code, message, field } on GraphQL payloads.
  # See docs/contracts/README.md section 2 for the canonical table.
  module Messages
    INVALID_CNJ = "Número de processo inválido. Confira os dígitos."
    NOT_FOUND = "Processo não encontrado na base."
    INVALID_ARGUMENT = "Parâmetro inválido."
    UNAUTHENTICATED = "Faça login para continuar."
    INVALID_CREDENTIALS = "E-mail ou senha inválidos."
    SUMMARY_UNAVAILABLE = "Não foi possível gerar o resumo agora."
    RATE_LIMITED = "Muitas tentativas. Aguarde um momento e tente novamente."
    INVALID_EMAIL = "Informe um e-mail válido."
    EMAIL_TAKEN = "Este e-mail já está em uso."
    INVALID_PASSWORD_LENGTH = "A senha deve ter de 10 a 72 caracteres."

    module_function

    # Default pt-BR message for an ErrorCode (symbol or string), or nil.
    def for(code)
      const_get(code.to_s, false) if code.to_s.match?(/\A[A-Z_]+\z/) && const_defined?(code.to_s, false)
    end

    # Builds a UserError-shaped hash: { code:, message:, field: }.
    def build(code, message, field: nil)
      { code: code, message: message, field: field }
    end
  end
end
