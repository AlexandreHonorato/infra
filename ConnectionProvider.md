# Descrição #
Esta classe é responsável por retornar uma instância de um Connection.

# Requisitos #
O ConnectionProvider é criado internamente pela SessionFactory, recebendo um Configuration como parâmetro.

O ConnectionProvider usa as seguintes chaves do Configuration:
  * ??? mostrar as chaves aqui. acho que ConnectionString e ConnectionStringName e outras referentes ao pool ???

Como não se deve manter uma conexão aberta indefinidamente nem ficar abrindo e fechando-as sempre, o ConnectionProvider deve

manter um pool de conexões para melhorar o desempenho do sistema.

# Tarefas #
  1. Ver quais as chaves de configuração o ConnectionProvider utiliza para configurar o connection;
  1. Fazer o ConnectionProvider retornar um novo connection a cada GetConnection;
  1. Ver quais as chaves de configuração o ConnectionProvider utiliza para configurar o Pool;
  1. Fazer o ConnectionProvider pegar o connection deste pool;