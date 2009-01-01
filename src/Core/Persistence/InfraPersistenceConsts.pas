unit InfraPersistenceConsts;

interface

const
  // Chaves do Configuration
  cCONFIGKEY_MAXCONNECTIONS = 'Pool.MaxConnections';
  cCONFIGKEY_CONNECTIONTIME = 'Pool.TimeExpirationConnection';

  // Valores padr�es para items do configuration
  cGlobalMaxConnections = 30;

resourcestring
  // Erros da persist�ncia
  cErrorConfigurationNotDefined = 'Configuration nao foi alimentado';
  cErrorConnectionNotFoundOnPool = 'Conex�o n�o encontrada no Pool deste Provider';
  cErrorAlreadyClosedConnection = 'Conex�o j� fechada';

// Constantes relacionadas com a conexao com o banco de dados
const
  cCONFIGKEY_DRIVER = 'Connection.Driver';
  cCONFIGKEY_HOSTNAME = 'Connection.HostName';
  cCONFIGKEY_PASSWORD = 'Connection.Password';
  cCONFIGKEY_USERNAME = 'Connection.UserName';
  cCONFIGKEY_DATABASENAME = 'Connection.DatabaseName';

implementation

end.
