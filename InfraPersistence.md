# Introdução #

Uma das maiores dificuldade dos programadores em cair de cabeça no mundo OO é o questionamento: "Será que este framework vai ser capaz de montar sozinho aquela instrução SQL super complexa que uso naquela parte do meu sistema?"

Sua preocupação faz todo sentido por que a maioria dos frameworks existentes só geram instruções mais simples, no máximo com joins, etc. Acabam te deixando na mão quando precisa de algo mais rebuscado como um union, chamada de uma função específica do banco, uma chamada a uma procedure, etc...

Outra grande dificuldade é poder portar a aplicação para OO com tranquilidade, sem ter de jogar tudo fora e começar a nova aplicação do zero.

O InfraPersistence é um simples e eficiente framework de persistência capaz de carregar ou armazenar objetos a partir de templates SQL.

## Características ##

  * Poder executar qualquer tipo de instrução SQL;
  * Remover qualquer instrução SQL da aplicação;
  * Arquivar em alguma espécie de repositório as instruções SQL como templates;
  * Mapeamento automático dos parâmetros;
  * Cache dos templates lidos;
  * Log automático do processamento;
  * Processar instruções SQL no SGDB e automaticamente retornar listas de objetos ou o número de registros afetados;

## Observações ##

No futuro iremos estar fazendo algumas automatizações via annotation no sentido de evitar a escrita dos templates SQL. Sem impedir o programador de se beneficiar deste recurso.

**Criamos um branch (a ser baixado via Tortoise SVN veja documento: Repositorio) para montar a nova camada de persistência, seria interessante se você puder acompanhar o desenvolvimento e contribuir com dicas e questionamentos no grupo:**

http://infra.googlecode.com/svn/branches/persistence/