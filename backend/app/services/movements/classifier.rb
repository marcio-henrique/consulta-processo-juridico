module Movements
  # Classifies a movement title as :milestone, :context or :noise
  # (docs/domains/legal-glossary.md section 3). Titles are folded (accents,
  # case, repeated spaces) and matched against an ordered rule list anchored at
  # the start of the title; the first match wins and unknown titles are
  # :context. A movement whose content has "Teor do ato:" is a :milestone for
  # its content, whatever its title ("Remetido ao DJE" carries the decision).
  #
  #   Movements::Classifier.call("Julgada Procedente a Ação") # => :milestone
  #   Movements::Classifier.call("Remetido ao DJE", content: "Teor do ato: ...") # => :milestone
  class Classifier
    RULES = [
      # --- Noise: publications and internal bookkeeping (glossary 3.3) ---
      [ /\Aremetido ao dje/, :noise ],
      [ /\Acertidao de publicacao expedida/, :noise ],
      [ /\Apublicado em/, :noise ],
      [ /\Aato ordinatorio - intimacao - (dje|portal)/, :noise ],
      [ /\Acertidao de cartorio expedida/, :noise ],
      [ /\Acertidao de remessa da intimacao/, :noise ],
      [ /\Aexpedido (certidao|termo|relatorio)/, :noise ],
      [ /\Aprocesso cadastrado/, :noise ],
      [ /\Aprocesso encaminhado para a distribuicao de recursos/, :noise ],
      [ /\Aprocesso encaminhado para o processamento de grupos e camaras/, :noise ],
      [ /\Arecebidos os autos pela entrada de recursos/, :noise ],
      # Only the automatic variant; the bare "Conclusos para o Relator" is context.
      [ /\Aconclusos para o relator \(expedido termo/, :noise ],

      # --- Milestones: the steps a layperson must be told about (glossary 3.1) ---
      [ /\A(distribuido|distribuicao)/, :milestone ],
      [ /\Arecebida a peticao inicial/, :milestone ],
      [ /\Aindeferida a peticao inicial/, :milestone ],
      [ /\Acontestacao juntada/, :milestone ],
      [ /\Areplica juntada/, :milestone ],
      [ /\Adesignada audiencia/, :milestone ],
      [ /\Aaudiencia/, :milestone ],
      [ /\Atermo de audiencia/, :milestone ],
      [ /\Apedido de homologacao de acordo/, :milestone ],
      [ /\Ahomologad[ao] /, :milestone ],
      [ /\A(nao )?concedida a (antecipacao de tutela|medida liminar)/, :milestone ],
      [ /\Ajulgad[ao]/, :milestone ],
      [ /\Ajulgamento virtual iniciado/, :milestone ],
      [ /\Aextint[oa] /, :milestone ],
      [ /\Apedido de extincao/, :milestone ],
      [ /\Aapelacao/, :milestone ],
      [ /\Acontrarrazoes/, :milestone ],
      [ /\Aacordao/, :milestone ],
      [ /\A(nao-)?provimento/, :milestone ],
      [ /\Atransito em julgado/, :milestone ],
      [ /\Acertidao de transito em julgado/, :milestone ],
      [ /\Aexecucao\/cumprimento de sentenca iniciada/, :milestone ],
      [ /\Apedido de expedicao de mandado de levantamento/, :milestone ],
      [ /\Adeterminada a expedicao de mandado de levantamento/, :milestone ],
      [ /\Amandado de levantamento expedido/, :milestone ],
      [ /\Aexpedido alvara de levantamento/, :milestone ],
      [ /\Aarquivado definitivamente/, :milestone ],
      [ /\Abaixa definitiva/, :milestone ],
      [ /\Aproferidas outras decisoes/, :milestone ]
    ].freeze

    def self.call(title, content: nil)
      return :milestone if Cleaner.teor?(content)

      RULES.each { |pattern, klass| return klass if fold(title).match?(pattern) }
      :context
    end

    # Lowercase, accents removed, whitespace collapsed.
    def self.fold(text)
      text.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.gsub(/\s+/, " ").strip
    end
    private_class_method :fold
  end
end
