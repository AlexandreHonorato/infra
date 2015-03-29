# Descrição #
Esta classe é responsável por executar as operação diretamente para o armazenador persistente (Banco, XML, Etc...).

# Requisitos #
O Connection é criado e retornado pelo ConnectionProvider sempre que necessário.

O Connection usa as seguintes chaves do Configuration:
  * ??? mostrar as chaves aqui. acho que ConnectionString? e ConnectionStringName? ???

# Tarefas #
  1. Criar a classe base Connection;
  1. Ver quais as chaves de configuração o Connection utiliza;
  1. Criar um descendente da classe base para driver Interbase/Firebird do DBExpress;