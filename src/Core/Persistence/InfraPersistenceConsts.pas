// xxx
unit InfraPersistenceConsts;

interface

const
  // Constantes relacionadas ao pool de conex�es
  cCONFIGKEY_MAXCONNECTIONS = 'Pool.MaxConnections';
  cCONFIGKEY_CONNECTIONTIME = 'Pool.TimeExpirationConnection';
  // Constantes relacionadas com a conexao com o banco de dados
  cCONFIGKEY_DRIVER = 'Connection.Driver';
  cCONFIGKEY_HOSTNAME = 'Connection.HostName';
  cCONFIGKEY_PASSWORD = 'Connection.Password';
  cCONFIGKEY_USERNAME = 'Connection.UserName';
  cCONFIGKEY_DATABASENAME = 'Connection.DatabaseName';
  // Constantes relacionadas aos templates SQL
  cCONFIGKEY_TEMPLATETYPE = 'Template.ClassType';
  cCONFIGKEY_TEMPLATEPATH = 'Template.Path';
  cCONFIGKEY_TEMPLATEEXT = 'Template.Ext';

  // Valores padr�es para items do configuration
  cGlobalMaxConnections = 30;

resourcestring
  // Erros da persist�ncia
  cErrorConfigurationNotDefined = 'Configuration nao foi alimentado';
  cErrorConnectionNotFoundOnPool = 'Conex�o n�o encontrada no Pool deste Provider';
  cErrorConnectionsLimitExceeded = 'N�mero m�ximo de conex�es excedido';
  cErrorAlreadyClosedConnection = 'Conex�o j� fechada';
  cErrorTemplateTryCreateClassBase = 'Classe base TemplateReader n�o deve ser instanciada';
  cErrorTemplateFileNotFound = 'Template %s n�o vazio ou n�o encontrado';
  cErrorTemplateTypeInvalid = 'Classe de leitura de templates inv�lida ou n�o definida';
  cErrorPersistenceEngineObjectIDUndefined = 'Tipo de objeto n�o definido no SQLCommand';
  cErrorPersistenceEngineParamNotFound = 'Par�metro %s n�o encontrado';
  cErrorPersistenceEngineAttributeNotFound = 'Atributo n�o encontrado para o alias %s (coluna: %s)';
  cErrorPersistenceEngineCannotMapAttribute = 'N�o foi possivel mapear valor para o atributo %s';
  // cErrorTemplatePathNotDefined = 'Caminho dos templates n�o definido';

implementation

end.