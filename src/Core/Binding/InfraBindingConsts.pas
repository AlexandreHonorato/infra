unit InfraBindingConsts;

interface

resourcestring
  // Erros da persist�ncia
  cErrorBindingProprtyNotExists = 'Bindable don''t have property %s';
  cErrorBindable2WayNotSupported = 'Bindable don''t supports TwoWay';
  cErrorLeftBindableNotDefined = 'Left Bindable undefined';
  cErrorRightBindableNotDefined = 'Right Bindable undefined';
  cErrorBindableNotDefined = 'Bindable not registred. Control: %s, Property: %s';
  cErrorBindableValueNotsupported =
    'ValueType not supported in this Bindable.'#13+
    'Control: %s, Property: %s, Type Supported: %s';
  cErrorBindableValuesIncompatibles = 'Incompatible Values: %s';
  cErrorDataContextNotIsInfraObject = 'Datacontext shoould be a InfraObject or descendent';
  cErrorBindingExpressionNotsupported = 'Cannot get property of this expression: %s';

implementation

end.
